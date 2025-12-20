// lib/features/verification/verification_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key, required this.qrData});

  final String qrData;

  bool _looksValidPayload(Map<String, dynamic>? payload) {
    return payload != null && payload['type'] == 'kitaid_verify';
  }

  /// ✅ UPDATED: include "Driving License" so it matches your Firestore doc id exactly.
  List<String> _cardDocCandidates(String cardIdFromQr) {
    final t = cardIdFromQr.trim().toLowerCase();

    if (t == 'ic' || t == 'mykad') {
      return [
        'IC',
        'ic',
        'MyKad',
        'mykad',
        'ic card',
        'mykad card',
      ];
    }

    if (t.contains('driving')) {
      return [
        'Driving License', // ✅ matches Firestore screenshot doc id
        'driving license',
        'Driving Licence',
        'driving licence',
        'driving_license',
        'driving_licence',
        'license',
        'licence',
      ];
    }

    return [cardIdFromQr, t];
  }

  /// ✅ Find the existing card document and return its data (or null)
  Future<Map<String, dynamic>?> _fetchCardData({
    required String uid,
    required String cardIdFromQr,
  }) async {
    final candidates = _cardDocCandidates(cardIdFromQr);

    for (final id in candidates) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('cards')
          .doc(id)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  String _pick(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  /// ✅ NEW: decide which fields to show per card type
  /// - IC/MyKad: show DOB, nationality, phone, address (location)
  /// - Driving License: show class, identity no, validity, nationality, address
  Map<String, String> _extractCardFields({
    required String cardIdFromQr,
    required Map<String, dynamic>? cardData,
  }) {
    final t = cardIdFromQr.trim().toLowerCase();
    final exists = cardData != null;

    if (!exists) {
      return {
        'dob': '-',
        'nationality': '-',
        'address': '-',
        'class': '-',
        'identityNo': '-',
        'validity': '-',
      };
    }

    final data = cardData!;

    // Shared fields (sometimes in different keys)
    final nationality = _pick(data, ['nationality', 'Nationality'], '-');
    final address = _pick(
      data,
      // ✅ you used location before but your driving license doc uses "address"
      ['location', 'address', 'Address'],
      '-',
    );

    if (t == 'ic' || t == 'mykad') {
      final dob = _pick(data, ['dob', 'DOB', 'dateOfBirth'], '-');
      return {
        'dob': dob,
        'nationality': nationality,
        'address': address,
        'class': '-',
        'identityNo': '-',
        'validity': '-',
      };
    }

    if (t.contains('driving')) {
      final licenseClass = _pick(data, ['class', 'Class'], '-');
      final identityNo = _pick(
        data,
        [
          'identity no',
          'identity_no',
          'identityNo',
          'ic',
          'IC',
          'IC No',
          'icNo',
          'ic_no',
        ],
        '-',
      );
      final validity = _pick(data, ['validity', 'Validity'], '-');

      return {
        'dob': '-', // driving license doc usually doesn't have DOB
        'nationality': nationality,
        'address': address,
        'class': licenseClass,
        'identityNo': identityNo,
        'validity': validity,
      };
    }

    // Other cards (fallback)
    return {
      'dob': _pick(data, ['dob', 'DOB', 'dateOfBirth'], '-'),
      'nationality': nationality,
      'address': address,
      'class': _pick(data, ['class', 'Class'], '-'),
      'identityNo': _pick(data, ['identity no', 'identityNo', 'ic', 'IC'], '-'),
      'validity': _pick(data, ['validity', 'Validity'], '-'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(qrData) as Map<String, dynamic>;
    } catch (_) {
      payload = null;
    }

    final isValid = _looksValidPayload(payload);
    final uid = isValid ? (payload!['uid']?.toString() ?? '') : '';
    final cardId = isValid ? (payload!['cardId']?.toString() ?? '') : '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(mysizes.defaultspace),
        child: (!isValid || uid.isEmpty)
            ? _error(theme, 'Invalid QR code')
            : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('Users').doc(uid).get(),
                builder: (context, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return _error(theme, 'User not found');
                  }

                  final user = userSnap.data!.data() ?? {};

                  // ✅ user basic info
                  final name = (user['Name'] ?? '-').toString();
                  final ic = (user['IC No'] ?? user['Passport No'] ?? '-').toString();
                  final phone = (user['Phone No'] ?? '-').toString();

                  // ✅ fetch card data (nationality/dob/address are stored here in your DB)
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchCardData(uid: uid, cardIdFromQr: cardId),
                    builder: (context, cardSnap) {
                      if (cardSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final cardData = cardSnap.data;
                      final cardExists = cardData != null;

                      final extracted = _extractCardFields(
                        cardIdFromQr: cardId,
                        cardData: cardData,
                      );

                      final t = cardId.trim().toLowerCase();
                      final isDriving = t.contains('driving');
                      final isIc = (t == 'ic' || t == 'mykad');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: mycolors.borderprimary),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cardExists ? Icons.verified : Icons.cancel,
                              size: 80,
                              color: cardExists ? Colors.green : Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cardExists ? 'Verified' : 'Not Verified',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cardExists ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 18),

                            _row(theme, 'Name:', name),
                            _row(theme, 'IC/Passport:', ic),

                            // ✅ Show different info based on card type
                            if (isIc) ...[
                              _row(theme, 'Date of Birth:', extracted['dob'] ?? '-'),
                              _row(theme, 'Nationality:', extracted['nationality'] ?? '-'),
                              _row(theme, 'Phone:', phone),
                              _row(theme, 'Address:', extracted['address'] ?? '-'),
                            ] else if (isDriving) ...[
                              _row(theme, 'Identity No:', extracted['identityNo'] ?? '-'),
                              _row(theme, 'Class:', extracted['class'] ?? '-'),
                              _row(theme, 'Nationality:', extracted['nationality'] ?? '-'),
                              _row(theme, 'Validity:', extracted['validity'] ?? '-'),
                              _row(theme, 'Address:', extracted['address'] ?? '-'),
                            ] else ...[
                              _row(theme, 'Nationality:', extracted['nationality'] ?? '-'),
                              _row(theme, 'Phone:', phone),
                              _row(theme, 'Address:', extracted['address'] ?? '-'),
                            ],

                            _row(theme, 'Card Type:', cardId),

                            const SizedBox(height: 6),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // ✅ wider so labels stay in one line
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: mycolors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mycolors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(ThemeData theme, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 80),
          const SizedBox(height: 12),
          Text(
            msg,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: mycolors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
