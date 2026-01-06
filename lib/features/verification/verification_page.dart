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

  // -------------------------
  // Helpers (case-insensitive detection)
  // -------------------------
  bool _isMyKadOrIcId(String id) {
    final t = id.trim().toLowerCase();
    // ✅ MyKad / IC only (NOT i-kad)
    return t == 'ic' || t == 'mykad' || t.contains('mykad');
  }

  bool _isIKadId(String id) {
    final t = id.trim().toLowerCase();
    return t == 'i-kad' || t.contains('i-kad') || t == 'ikad' || t.contains('ikad');
  }

  // -------------------------
  // CARDS
  // -------------------------
  List<String> _cardDocCandidates(String cardIdFromQr) {
    final t = cardIdFromQr.trim().toLowerCase();

    // ✅ IC / MyKad candidates
    if (_isMyKadOrIcId(cardIdFromQr)) {
      return [
        'IC',
        'ic',
        'Ic',
        'MyKad',
        'mykad',
        'MYKAD',
        'mykad card',
        'ic card',
      ];
    }

    // ✅ i-Kad candidates
    if (_isIKadId(cardIdFromQr)) {
      return [
        'I-Kad',
        'i-kad',
        'i-Kad',
        'IKad',
        'iKad',
        'ikad',
      ];
    }

    // ✅ Driving License candidates (unchanged)
    if (t.contains('driving')) {
      return [
        'Driving License',
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

  /// get the existing card document and return its data (or null)
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

  /// ✅ NEW: extract fields per card type (MyKad vs i-Kad vs Driving)
  Map<String, String> _extractCardFields({
    required String cardIdFromQr,
    required Map<String, dynamic>? cardData,
  }) {
    final t = cardIdFromQr.trim().toLowerCase();
    final exists = cardData != null;

    if (!exists) {
      return {
        'cardType': cardIdFromQr,
        'name': '-',
        'dob': '-',
        'nationality': '-',
        'location': '-',
        'mykadNo': '-',
        'passportNo': '-',
        'expiryDate': '-',
        'institution': '-',
        'referenceNo': '-',
        'gender': '-',
        'address': '-',
        'class': '-',
        'identityNo': '-',
        'validity': '-',
      };
    }

    final data = cardData!;

    final name = _pick(data, ['name', 'Name', 'NAME'], '-');
    final dob = _pick(
      data,
      ['dob', 'DOB', 'Date of Birth', 'dateOfBirth', 'date of birth'],
      '-',
    );
    final nationality = _pick(
      data,
      ['nationality', 'Nationality', 'NATIONALITY'],
      '-',
    );
    final location = _pick(
      data,
      ['location', 'Location', 'LOCATION', 'address', 'Address'],
      '-',
    );

    // ✅ MyKad/IC
    if (_isMyKadOrIcId(cardIdFromQr) || t == 'ic' || t == 'mykad') {
      final mykadNo = _pick(
        data,
        [
          'icNo',
          'ICNo',
          'IC No',
          'ic_no',
          'mykadNo',
          'MyKadNo',
          'MyKad No',
          'MYKADNO',
        ],
        '-',
      );

      return {
        'cardType': cardIdFromQr,
        'name': name,
        'dob': dob,
        'nationality': nationality,
        'location': location,
        'mykadNo': mykadNo,
        'passportNo': '-',
        'expiryDate': '-',
        'institution': '-',
        'referenceNo': '-',
        'gender': '-',
        'address': '-',
        'class': '-',
        'identityNo': '-',
        'validity': '-',
      };
    }

    // ✅ i-Kad
    if (_isIKadId(cardIdFromQr)) {
      final passportNo = _pick(
        data,
        [
          'passport no',
          'Passport No',
          'PASSPORT NO',
          'passportNo',
          'passport_no',
          'PassportNo',
          'PASSPORTNO',
        ],
        '-',
      );

      final expiryDate = _pick(
        data,
        [
          'expiry date',
          'Expiry Date',
          'EXPIRY DATE',
          'expiryDate',
          'expiry_date',
          'date of expiry',
          'Date of Expiry',
          'date_of_expiry',
          'validUntil',
          'valid_until',
        ],
        '-',
      );

      final institution = _pick(
        data,
        [
          'institution',
          'Institution',
          'INSTITUTION',
          'instituation', // typo-safe
          'Instituation',
          'INSTITUATION',
        ],
        '-',
      );

      final referenceNo = _pick(
        data,
        [
          'reference no',
          'Reference No',
          'REFERENCE NO',
          'referenceNo',
          'reference_no',
          'refNo',
          'ref_no',
        ],
        '-',
      );

      final gender = _pick(
        data,
        [
          'gender',
          'Gender',
          'GENDER',
          'sex',
          'Sex',
          'SEX',
        ],
        '-',
      );

      return {
        'cardType': cardIdFromQr,
        'name': name,
        'dob': dob,
        'nationality': nationality,
        'location': location,
        'mykadNo': '-',
        'passportNo': passportNo,
        'expiryDate': expiryDate,
        'institution': institution,
        'referenceNo': referenceNo,
        'gender': gender,
        'address': '-',
        'class': '-',
        'identityNo': '-',
        'validity': '-',
      };
    }

    // ✅ Driving License (unchanged)
    if (t.contains('driving')) {
      final address = _pick(
        data,
        ['address', 'Address', 'location', 'Location'],
        '-',
      );

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

      final validity = _pick(
        data,
        ['validity', 'Validity', 'validFromTo', 'valid_from_to'],
        '-',
      );

      return {
        'cardType': cardIdFromQr,
        'name': name,
        'dob': '-',
        'nationality': nationality,
        'location': address,
        'mykadNo': '-',
        'passportNo': '-',
        'expiryDate': '-',
        'institution': '-',
        'referenceNo': '-',
        'gender': '-',
        'address': address,
        'class': licenseClass,
        'identityNo': identityNo,
        'validity': validity,
      };
    }

    // ✅ Other cards (fallback)
    return {
      'cardType': cardIdFromQr,
      'name': name,
      'dob': dob,
      'nationality': nationality,
      'location': location,
      'mykadNo': '-',
      'passportNo': '-',
      'expiryDate': '-',
      'institution': '-',
      'referenceNo': '-',
      'gender': '-',
      'address': location,
      'class': _pick(data, ['class', 'Class'], '-'),
      'identityNo': _pick(data, ['identity no', 'identityNo', 'ic', 'IC'], '-'),
      'validity': _pick(data, ['validity', 'Validity'], '-'),
    };
  }

  // -------------------------
  // DOCS (unchanged)
  // -------------------------
  String _getLoose(Map<String, dynamic> map, List<String> keys, String fallback) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final normMap = <String, dynamic>{};
    for (final e in map.entries) {
      normMap[norm(e.key.toString())] = e.value;
    }

    for (final k in keys) {
      final v = normMap[norm(k)];
      final out = (v ?? '').toString().trim();
      if (out.isNotEmpty) return out;
    }
    return fallback;
  }

  Future<Map<String, dynamic>?> _fetchDocData({
    required String uid,
    required String docIdFromQr,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('docs')
        .doc(docIdFromQr)
        .get();

    if (doc.exists) return doc.data();
    return null;
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

    final uid = isValid ? (payload!['uid']?.toString().trim() ?? '') : '';
    final kind =
        isValid ? (payload!['kind']?.toString().trim().toLowerCase() ?? 'card') : 'card';

    final cardId = isValid ? (payload!['cardId']?.toString() ?? '') : '';
    final docId = isValid ? (payload!['docId']?.toString() ?? '') : '';
    final docTitleFromQr = isValid ? (payload!['docTitle']?.toString() ?? '') : '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(mysizes.defaultspace),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: (!isValid || uid.isEmpty)
                    ? _error(theme, 'Invalid QR code (missing uid)')
                    : (kind == 'doc')
                        // DOC UI (kept as your code)
                        ? FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance.collection('Users').doc(uid).get(),
                            builder: (context, userSnap) {
                              if (userSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!userSnap.hasData || !userSnap.data!.exists) {
                                return _error(theme, 'User not found');
                              }

                              final user = userSnap.data!.data() ?? {};
                              final name = (user['Name'] ?? '-').toString();
                              final ic =
                                  (user['IC No'] ?? user['Passport No'] ?? '-').toString();
                              final phone = (user['Phone No'] ?? '-').toString();

                              if (docId.trim().isEmpty) {
                                return _error(theme, 'Invalid DOC QR (missing docId)');
                              }

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _fetchDocData(uid: uid, docIdFromQr: docId),
                                builder: (context, docSnap) {
                                  if (docSnap.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final docData = docSnap.data;
                                  final docExists = docData != null;

                                  final isPassport = (docTitleFromQr
                                          .toLowerCase()
                                          .contains('passport') ||
                                      docId.toLowerCase().contains('passport'));

                                  return Container(
                                    width: double.infinity,
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
                                          docExists ? Icons.verified : Icons.cancel,
                                          size: 80,
                                          color: docExists ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          docExists ? 'Verified' : 'Not Verified',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: docExists ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 18),

                                        _row(theme, 'Name:', name),
                                        _row(theme, 'IC/Passport:', ic),

                                        if (!docExists) ...[
                                          const SizedBox(height: 8),
                                          _row(
                                            theme,
                                            'Document:',
                                            docTitleFromQr.isEmpty ? docId : docTitleFromQr,
                                          ),
                                        ] else if (isPassport) ...[
                                          _row(
                                            theme,
                                            'Passport No:',
                                            _getLoose(
                                              docData!,
                                              ['passport no', 'passport_no', 'Passport No', 'passportNo'],
                                              '-',
                                            ),
                                          ),
                                          _row(
                                            theme,
                                            'Nationality:',
                                            _getLoose(docData!, ['nationality', 'Nationality'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Country Code:',
                                            _getLoose(docData!, ['countrycode', 'country code', 'country_code'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Date of Birth:',
                                            _getLoose(docData!, ['date of birth', 'dob', 'DOB'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Place of Birth:',
                                            _getLoose(docData!, ['place of birth', 'place_of_birth'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Sex:',
                                            _getLoose(docData!, ['sex', 'Sex'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Type:',
                                            _getLoose(docData!, ['type', 'Type'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Identity No:',
                                            _getLoose(docData!, ['identity no', 'identity_no', 'identityNo'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Height:',
                                            _getLoose(docData!, ['height', 'Height'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Issuing Office:',
                                            _getLoose(docData!, ['issuing office', 'issuing_office'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Date of Issue:',
                                            _getLoose(docData!, ['date of issue', 'date_of_issue'], '-'),
                                          ),
                                          _row(
                                            theme,
                                            'Date of Expiry:',
                                            _getLoose(docData!, ['date of expiry', 'date_of_expiry', 'expiry'], '-'),
                                          ),
                                          _row(theme, 'Phone:', phone),
                                        ] else ...[
                                          _row(
                                            theme,
                                            'Document:',
                                            docTitleFromQr.isEmpty ? docId : docTitleFromQr,
                                          ),
                                          _row(
                                            theme,
                                            'Status:',
                                            (payload?['status']?.toString().trim().isNotEmpty ?? false)
                                                ? payload!['status'].toString()
                                                : 'Active',
                                          ),
                                          _row(theme, 'Phone:', phone),
                                        ],
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        // -------------------------
                        // CARDS UI (UPDATED)
                        // -------------------------
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
                              final nameFromUser = (user['Name'] ?? '-').toString();
                              final icPassportFromUser =
                                  (user['IC No'] ?? user['Passport No'] ?? '-').toString();
                              final phone = (user['Phone No'] ?? '-').toString();

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
                                  final isMyKad = _isMyKadOrIcId(cardId);
                                  final isIKad = _isIKadId(cardId);

                                  // ✅ If card has "name", prefer it, else user name
                                  final displayName =
                                      (extracted['name'] ?? '').trim().isNotEmpty &&
                                              extracted['name'] != '-'
                                          ? extracted['name']!
                                          : nameFromUser;

                                  // ✅ Show correct top ID line depending on card type
                                  String idLineLabel = 'IC/Passport:';
                                  String idLineValue = icPassportFromUser;

                                  if (isMyKad) {
                                    idLineLabel = 'MyKad No:';
                                    idLineValue = extracted['mykadNo'] ?? '-';
                                  } else if (isIKad) {
                                    idLineLabel = 'Passport No:';
                                    idLineValue = extracted['passportNo'] ?? '-';
                                  }

                                  return Container(
                                    width: double.infinity,
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

                                        _row(theme, 'Name:', displayName),
                                        _row(theme, idLineLabel, idLineValue),

                                        if (isMyKad) ...[
                                          _row(theme, 'Date of Birth:', extracted['dob'] ?? '-'),
                                          _row(theme, 'Nationality:', extracted['nationality'] ?? '-'),
                                          _row(theme, 'Phone:', phone),
                                          _row(theme, 'Location:', extracted['location'] ?? '-'),
                                        ] else if (isIKad) ...[
                                          _row(theme, 'Date of Birth:', extracted['dob'] ?? '-'),
                                          _row(theme, 'Nationality:', extracted['nationality'] ?? '-'),
                                          _row(theme, 'Gender:', extracted['gender'] ?? '-'),
                                          _row(theme, 'Expiry Date:', extracted['expiryDate'] ?? '-'),
                                          _row(theme, 'Institution:', extracted['institution'] ?? '-'),
                                          _row(theme, 'Reference No:', extracted['referenceNo'] ?? '-'),
                                          _row(theme, 'Phone:', phone),
                                          _row(theme, 'Location:', extracted['location'] ?? '-'),
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
            ),
          );
        },
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
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: mysizes.fontMd,
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
                fontSize: mysizes.fontMd,
                fontWeight: FontWeight.w400,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
