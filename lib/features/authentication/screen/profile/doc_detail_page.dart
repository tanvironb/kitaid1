// lib/features/authentication/screen/profile/doc_detail_page.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DocDetailPage extends StatefulWidget {
  const DocDetailPage({
    super.key,
    required this.uid,
    required this.docId, // Firestore doc id inside Users/{uid}/docs/{docId}
    required this.docTitle,
    required this.docDescription,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
  });

  final String uid;
  final String docId;

  final String docTitle;
  final String docDescription;

  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  @override
  State<DocDetailPage> createState() => _DocDetailPageState();
}

class _DocDetailPageState extends State<DocDetailPage> {
  final _db = FirebaseFirestore.instance;

  bool _isFavorite = false;
  bool _favBusy = false;

  String _favIdFor(String title) {
    final key =
        title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'doc_$key';
  }

  bool _isPassportDoc() {
    final t1 = widget.docTitle.trim().toLowerCase();
    final t2 = widget.docId.trim().toLowerCase();
    return t1.contains('passport') || t2.contains('passport');
  }

  // -----------------------
  // Copy helpers
  // -----------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copyText(String text, {String toastMsg = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast(toastMsg);
  }

  // -----------------------
  // Loose key matcher
  // -----------------------
  static String _stringify(dynamic v) => (v ?? '').toString().trim();

  static String _getLoose(Map<String, dynamic> map, List<String> keys) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final normMap = <String, dynamic>{};
    for (final e in map.entries) {
      normMap[norm(e.key.toString())] = e.value;
    }

    for (final k in keys) {
      final v = normMap[norm(k)];
      final out = _stringify(v);
      if (out.isNotEmpty) return out;
    }
    return '';
  }

  // -----------------------
  // Load data
  // -----------------------
  Future<_DocPayload> _load() async {
    final uid = widget.uid;

    // favorite state
    final favRef = _db
        .collection('Users')
        .doc(uid)
        .collection('favorites')
        .doc(_favIdFor(widget.docTitle));
    final favSnap = await favRef.get();
    _isFavorite = favSnap.exists;

    // user profile doc
    final userSnap = await _db.collection('Users').doc(uid).get();
    final user = userSnap.data() ?? {};

    // ✅ doc data
    final docRef = _db
        .collection('Users')
        .doc(uid)
        .collection('docs')
        .doc(widget.docId);

    final docSnap = await docRef.get();

    return _DocPayload(
      docExists: docSnap.exists,
      docPath: docRef.path,
      userData: user,
      docData: docSnap.data() ?? {},
    );
  }

  Future<void> _toggleFavorite({
    required String ownerName,
    required String ownerDob,
    required String ownerCountry,
  }) async {
    final uid = widget.uid;
    if (_favBusy) return;

    setState(() => _favBusy = true);

    try {
      final favRef = _db
          .collection('Users')
          .doc(uid)
          .collection('favorites')
          .doc(_favIdFor(widget.docTitle));

      if (_isFavorite) {
        await favRef.delete();
        setState(() => _isFavorite = false);
        _toast('Removed from favorites');
      } else {
        await favRef.set({
          'type': 'doc',
          'title': widget.docTitle,
          'description': widget.docDescription,
          'ownerName': ownerName,
          'ownerDob': ownerDob,
          'ownerCountry': ownerCountry,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => _isFavorite = true);
        _toast('Added to favorites');
      }
    } catch (_) {
      _toast('Favorite failed');
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<_DocPayload>(
      future: _load(),
      builder: (context, snap) {
        // show loading
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              foregroundColor: mycolors.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // show error
        if (snap.hasError) {
          return _errorScaffold(
            theme,
            'Failed to load document.\n${snap.error}',
          );
        }

        final data = snap.data!;
        final user = data.userData;
        final doc = data.docData;

        // ✅ if doc missing / denied, show clear message instead of "-"
        if (!data.docExists) {
          return _errorScaffold(
            theme,
            'Document not found or permission denied.\n\nPath:\n${data.docPath}\n\nOpened docId:\n${widget.docId}',
          );
        }

        // Prefer doc fields first, then fallback to user profile, then widget params.
        final ownerName = _getLoose(doc, const ['name', 'Name']).isNotEmpty
            ? _getLoose(doc, const ['name', 'Name'])
            : (_getLoose(user, const ['Name', 'name', 'fullName', 'FullName'])
                    .isNotEmpty
                ? _getLoose(user, const ['Name', 'name', 'fullName', 'FullName'])
                : widget.ownerName);

        final ownerDob = _getLoose(doc, const [
          'date of birth',
          'dob',
          'Date of Birth',
          'DOB',
        ]).isNotEmpty
            ? _getLoose(doc, const ['date of birth', 'dob', 'Date of Birth', 'DOB'])
            : (_getLoose(user, const ['Date of Birth', 'DOB', 'dob', 'birthDate'])
                    .isNotEmpty
                ? _getLoose(
                    user, const ['Date of Birth', 'DOB', 'dob', 'birthDate'])
                : widget.ownerDob);

        final ownerCountry = _getLoose(doc, const [
          'nationality',
          'Nationality',
          'country',
          'Country',
        ]).isNotEmpty
            ? _getLoose(doc, const ['nationality', 'Nationality', 'country', 'Country'])
            : (_getLoose(user, const ['Nationality', 'nationality', 'Country', 'country'])
                    .isNotEmpty
                ? _getLoose(
                    user, const ['Nationality', 'nationality', 'Country', 'country'])
                : widget.ownerCountry);

        final details = _getDetailsByDocType(
          ownerName: ownerName,
          ownerDob: ownerDob,
          ownerCountry: ownerCountry,
          docData: doc,
          userData: user,
        );

        // ✅ QR payload MUST be JSON because VerificationPage uses jsonDecode()
        final qrPayload = <String, dynamic>{
          "type": "kitaid_verify",
          "kind": "doc",
          "uid": widget.uid,
          "docId": widget.docId,
          "docTitle": widget.docTitle,
          "ownerName": ownerName,
          "ownerDob": ownerDob,
          "ownerCountry": ownerCountry,
          "ts": DateTime.now().millisecondsSinceEpoch,
        };
        final qrData = jsonEncode(qrPayload);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            foregroundColor: mycolors.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Done',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.Primary,
                    fontWeight: FontWeight.w700,
                    fontSize: mysizes.fontSm,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(mysizes.defaultspace),
              children: [
                // ================= ACTIONS =================
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final all = details
                            .map((e) => '${e.label}: ${e.value}')
                            .join('\n');
                        await _copyText(all, toastMsg: 'Copied all details');
                      },
                      icon: const Icon(Icons.copy),
                      color: mycolors.textPrimary,
                      tooltip: 'Copy all',
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share (TODO)')),
                        );
                      },
                      icon: const Icon(Icons.ios_share),
                      color: mycolors.textPrimary,
                    ),
                    IconButton(
                      onPressed: () => _toggleFavorite(
                        ownerName: ownerName,
                        ownerDob: ownerDob,
                        ownerCountry: ownerCountry,
                      ),
                      icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
                      color:
                          _isFavorite ? mycolors.Primary : mycolors.textPrimary,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= QR CODE =================
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: mycolors.borderprimary),
                    ),
                    child: QrImageView(
                      data: qrData,
                      size: 120,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= DETAILS TITLE + COPY =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: mycolors.Primary,
                        fontWeight: FontWeight.w700,
                        fontSize: mysizes.fontMd,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final all = details
                            .map((e) => '${e.label}: ${e.value}')
                            .join('\n');
                        await _copyText(all, toastMsg: 'Copied');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= DETAILS BOX =================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mycolors.borderprimary),
                  ),
                  child: Column(
                    children: _buildDetails(theme, details),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Scaffold _errorScaffold(ThemeData theme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: mycolors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(mysizes.defaultspace),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mycolors.textPrimary,
              fontSize: mysizes.fontMd,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetails(ThemeData theme, List<_DetailItem> items) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_detailRow(theme, items[i].label, items[i].value));
      if (i != items.length - 1) widgets.add(const Divider(height: 1));
    }
    return widgets;
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _copyText(displayValue, toastMsg: 'Copied $label'),
      onLongPress: () => _copyText('$label: $displayValue', toastMsg: 'Copied'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: mycolors.textPrimary,
                fontSize: mysizes.fontMd,
              ),
            ),
            Expanded(
              child: Text(
                displayValue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                  fontSize: mysizes.fontMd,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy,
              size: 16,
              color: mycolors.textPrimary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  List<_DetailItem> _getDetailsByDocType({
    required String ownerName,
    required String ownerDob,
    required String ownerCountry,
    required Map<String, dynamic> docData,
    required Map<String, dynamic> userData,
  }) {
    if (_isPassportDoc()) {
      String fromDoc(List<String> keys) => _getLoose(docData, keys);
      String fromUser(List<String> keys) => _getLoose(userData, keys);

      String safe(List<String> keys) {
        final v = fromDoc(keys);
        return v.isEmpty ? '-' : v;
      }

      final name = fromDoc(['name', 'Name']).isNotEmpty
          ? fromDoc(['name', 'Name'])
          : ownerName;

      final dob = fromDoc(['date of birth', 'dob', 'DOB', 'Date of Birth'])
              .isNotEmpty
          ? fromDoc(['date of birth', 'dob', 'DOB', 'Date of Birth'])
          : ownerDob;

      final nationality = fromDoc(['nationality', 'Nationality']).isNotEmpty
          ? fromDoc(['nationality', 'Nationality'])
          : ownerCountry;

      final passportNo =
          fromDoc(['passport no', 'passport_no', 'Passport No', 'passportNo'])
                  .isNotEmpty
              ? fromDoc(
                  ['passport no', 'passport_no', 'Passport No', 'passportNo'])
              : (fromUser(['Passport No', 'passportNo']).isNotEmpty
                  ? fromUser(['Passport No', 'passportNo'])
                  : '-');

      final countryCode = fromDoc(
          ['countrycode', 'country code', 'country_code', 'country code:']);

      return [
        _DetailItem('Name', name),
        _DetailItem('Passport No', passportNo),
        _DetailItem('Nationality', nationality),
        _DetailItem('Country Code', countryCode.isEmpty ? '-' : countryCode),
        _DetailItem('Date of Birth', dob),
        _DetailItem('Place of Birth',
            safe(['place of birth', 'place_of_birth', 'Place of Birth'])),
        _DetailItem('Sex', safe(['sex', 'Sex'])),
        _DetailItem('Type', safe(['type', 'Type'])),
        _DetailItem('Identity No',
            safe(['identity no', 'identity_no', 'Identity No'])),
        _DetailItem('Height', safe(['height', 'Height'])),
        _DetailItem('Issuing Office',
            safe(['issuing office', 'issuing_office', 'Issuing Office'])),
        _DetailItem('Date of Issue',
            safe(['date of issue', 'date_of_issue', 'Date of Issue'])),
        _DetailItem('Date of Expiry',
            safe(['date of expiry', 'date_of_expiry', 'Date of Expiry', 'expiry'])),
        _DetailItem('Status', widget.docDescription),
      ];
    }

    // International Driving License (and others) -> simple details
    return [
      _DetailItem('Owner', ownerName),
      _DetailItem('Document', widget.docTitle),
      _DetailItem('Status', widget.docDescription),
    ];
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}

class _DocPayload {
  final bool docExists;
  final String docPath;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> docData;

  const _DocPayload({
    required this.docExists,
    required this.docPath,
    required this.userData,
    required this.docData,
  });
}
