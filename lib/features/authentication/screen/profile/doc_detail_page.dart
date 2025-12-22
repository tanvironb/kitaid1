// lib/features/authentication/screen/profile/doc_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DocDetailPage extends StatefulWidget {
  const DocDetailPage({
    super.key,
    required this.uid, // ✅ MUST be passed from profile page
    required this.docId, // ✅ doc id inside Users/{uid}/docs/{docId} (e.g. "Passport")
    required this.docTitle,
    required this.docDescription,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
    this.previewAsset,
  });

  final String uid;
  final String docId;

  final String docTitle;
  final String docDescription;

  // fallback values (used if Firebase fields are missing)
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  final String? previewAsset;

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

  bool _isPassport(String title) {
    final t = title.trim().toLowerCase();
    return t.contains('passport');
  }

  // -----------------------
  // Copy helpers (same style as CardDetailPage)
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
  // Value helpers
  // -----------------------
  static String _stringify(dynamic v) => (v ?? '').toString().trim();

  static bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    return s.startsWith('http://') || s.startsWith('https://');
  }

  /// ✅ Loose matcher: removes spaces/underscores/colons etc.
  /// So these all match the same key:
  /// "country code", "country_code", "countrycode", "country code:"
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

    // doc data (Users/{uid}/docs/{docId})
    final docSnap = await _db
        .collection('Users')
        .doc(uid)
        .collection('docs')
        .doc(widget.docId)
        .get();

    final docData = docSnap.data() ?? {};

    // preview url: cover url stored in field "Passport" (per your screenshot)
    // but we also support variants safely.
    final previewUrl = _getLoose(docData, const [
      'Passport',
      'passport',
      'imageUrl',
      'url',
      'coverUrl',
      'previewUrl',
    ]);

    return _DocPayload(
      previewUrl: _looksLikeUrl(previewUrl) ? previewUrl : null,
      userData: user,
      docData: docData,
    );
  }

  Future<void> _toggleFavorite({
    required String ownerName,
    required String ownerDob,
    required String ownerCountry,
    required String? previewUrl,
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
          'previewUrl': previewUrl,
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
        final data = snap.data;

        final user = data?.userData ?? {};
        final doc = data?.docData ?? {};

        // Prefer doc fields first, then fallback to user profile, then passed widget params.
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
            : (_getLoose(user, const [
                        'Date of Birth',
                        'DOB',
                        'dob',
                        'birthDate'
                      ]).isNotEmpty
                ? _getLoose(user, const [
                    'Date of Birth',
                    'DOB',
                    'dob',
                    'birthDate'
                  ])
                : widget.ownerDob);

        final ownerCountry = _getLoose(doc, const [
          'nationality',
          'Nationality',
          'country',
          'Country',
        ]).isNotEmpty
            ? _getLoose(doc, const ['nationality', 'Nationality', 'country', 'Country'])
            : (_getLoose(user, const [
                        'Nationality',
                        'nationality',
                        'Country',
                        'country'
                      ]).isNotEmpty
                ? _getLoose(user, const [
                    'Nationality',
                    'nationality',
                    'Country',
                    'country'
                  ])
                : widget.ownerCountry);

        final previewUrl = data?.previewUrl;

        final details = _getDetailsByDocType(
          ownerName: ownerName,
          ownerDob: ownerDob,
          ownerCountry: ownerCountry,
          docData: doc,
          userData: user,
        );

        final qrData =
            'KitaID|DOC|${widget.docTitle}|${widget.docDescription}|$ownerName|$ownerDob|$ownerCountry';

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
                // ================= PREVIEW =================
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: _buildPreview(theme, previewUrl),
                  ),
                ),

                const SizedBox(height: 14),

                // ================= ACTIONS =================
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final all =
                            details.map((e) => '${e.label}: ${e.value}').join('\n');
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
                        previewUrl: previewUrl,
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
                        final all =
                            details.map((e) => '${e.label}: ${e.value}').join('\n');
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

  Widget _buildPreview(ThemeData theme, String? previewUrl) {
    if (previewUrl != null && previewUrl.trim().isNotEmpty) {
      return Image.network(
        previewUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackPreview(theme),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: mycolors.bgPrimary,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
      );
    }

    if (widget.previewAsset != null) {
      return Image.asset(widget.previewAsset!, fit: BoxFit.cover);
    }

    return _fallbackPreview(theme);
  }

  Widget _fallbackPreview(ThemeData theme) {
    return Container(
      color: mycolors.bgPrimary,
      alignment: Alignment.center,
      child: Text(
        '${widget.docTitle} Preview',
        style: theme.textTheme.titleMedium?.copyWith(
          color: mycolors.textPrimary,
          fontWeight: FontWeight.w600,
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

  // ✅ Passport shows fields from Users/{uid}/docs/{docId} with loose matching
  List<_DetailItem> _getDetailsByDocType({
    required String ownerName,
    required String ownerDob,
    required String ownerCountry,
    required Map<String, dynamic> docData,
    required Map<String, dynamic> userData,
  }) {
    if (_isPassport(widget.docTitle)) {
      String fromDoc(List<String> keys) => _getLoose(docData, keys);
      String fromUser(List<String> keys) => _getLoose(userData, keys);

      final name = fromDoc(['name', 'Name']).isNotEmpty
          ? fromDoc(['name', 'Name'])
          : ownerName;

      final dob = fromDoc(['date of birth', 'dob', 'DOB', 'Date of Birth']).isNotEmpty
          ? fromDoc(['date of birth', 'dob', 'DOB', 'Date of Birth'])
          : ownerDob;

      final nationality =
          fromDoc(['nationality', 'Nationality']).isNotEmpty
              ? fromDoc(['nationality', 'Nationality'])
              : ownerCountry;

      final passportNo = fromDoc([
        'passport no',
        'passport_no',
        'Passport No',
        'passportNo',
      ]).isNotEmpty
          ? fromDoc(['passport no', 'passport_no', 'Passport No', 'passportNo'])
          : (fromUser(['Passport No', 'passportNo']).isNotEmpty
              ? fromUser(['Passport No', 'passportNo'])
              : '-');

      // ✅ THIS will now match: countrycode / country code / country_code / country code:
      final countryCode = fromDoc([
        'countrycode',
        'country code',
        'country_code',
        'country code:',
      ]);

      return [
        _DetailItem('Name', name),
        _DetailItem('Passport No', passportNo),
        _DetailItem('Nationality', nationality),
        _DetailItem('Country Code', countryCode.isEmpty ? '-' : countryCode),
        _DetailItem('Date of Birth', dob),
        _DetailItem('Place of Birth',
            fromDoc(['place of birth', 'place_of_birth', 'Place of Birth']).isEmpty
                ? '-'
                : fromDoc(['place of birth', 'place_of_birth', 'Place of Birth'])),
        _DetailItem('Sex', fromDoc(['sex', 'Sex']).isEmpty ? '-' : fromDoc(['sex', 'Sex'])),
        _DetailItem('Type', fromDoc(['type', 'Type']).isEmpty ? '-' : fromDoc(['type', 'Type'])),
        _DetailItem(
            'Identity No',
            fromDoc(['identity no', 'identity_no', 'Identity No', 'ic', 'IC No'])
                    .isEmpty
                ? '-'
                : fromDoc(['identity no', 'identity_no', 'Identity No', 'ic', 'IC No'])),
        _DetailItem('Height',
            fromDoc(['height', 'Height']).isEmpty ? '-' : fromDoc(['height', 'Height'])),
        _DetailItem(
            'Issuing Office',
            fromDoc(['issuing office', 'issuing_office', 'Issuing Office']).isEmpty
                ? '-'
                : fromDoc(['issuing office', 'issuing_office', 'Issuing Office'])),
        _DetailItem(
            'Date of Issue',
            fromDoc(['date of issue', 'date_of_issue', 'Date of Issue']).isEmpty
                ? '-'
                : fromDoc(['date of issue', 'date_of_issue', 'Date of Issue'])),
        _DetailItem(
            'Date of Expiry',
            fromDoc(['date of expiry', 'date_of_expiry', 'Date of Expiry', 'expiry'])
                    .isEmpty
                ? '-'
                : fromDoc(['date of expiry', 'date_of_expiry', 'Date of Expiry', 'expiry'])),
        _DetailItem('Status', widget.docDescription),
      ];
    }

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
  final String? previewUrl;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> docData;

  const _DocPayload({
    required this.previewUrl,
    required this.userData,
    required this.docData,
  });
}
