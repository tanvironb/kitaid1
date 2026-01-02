import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CardDetailPage extends StatefulWidget {
  const CardDetailPage({
    super.key,
    required this.cardTitle,
    required this.cardIdLabel,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
    this.imageAsset,
    this.imageUrl,
  });

  final String cardTitle;
  final String cardIdLabel;

  // Fallback values if Firestore fields not found
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  /// Local asset fallback 
  final String? imageAsset;

  /// Firebase Storage download URL 
  final String? imageUrl;

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  String? _fetchedImageUrl;
  bool _loadingImage = false;

  /// Card document fields
  Map<String, dynamic>? _cardData;

  /// ✅ The EXACT Firestore document id that was found (e.g. "MyKad" or "I-Kad")
  String? _resolvedCardType;

  /// Favorites state
  bool _isFavorite = false;
  bool _loadingFavorite = true;

  @override
  void initState() {
    super.initState();

    final hasIncomingUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    _autoFetchCardFromFirestore(fetchImage: !hasIncomingUrl);
    _loadFavorite();
  }

  // -----------------------
  // Helpers
  // -----------------------
  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.startsWith('http://') || s.startsWith('https://');
  }

  String? _extractAnyUrl(Map<String, dynamic>? data) {
    if (data == null) return null;

    const keysToTry = [
      'imageUrl',
      'imageURL',
      'url',
      'front',
      'card',
      'photo',
      'ic',
      'mykad',
      'MyKad',
      'I-Kad',
      'i-kad',
      'license',
      'licence',
      'drivingLicense',
      'driving_license',
    ];

    for (final k in keysToTry) {
      final v = data[k]?.toString();
      if (_looksLikeUrl(v)) return v!.trim();
    }

    for (final entry in data.entries) {
      final v = entry.value?.toString();
      if (_looksLikeUrl(v)) return v!.trim();
    }

    return null;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _copyText(String text, {String toastMsg = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast(toastMsg);
  }

  String _favoriteKey() {
    final t = widget.cardTitle.trim().toLowerCase();
    if (t.contains('driving')) return 'driving_license';
    if (t.contains('mykad') || t.contains('i-kad') || t == 'ic') return 'ic';
    return t.replaceAll(RegExp(r'\s+'), '_');
  }

  String _cardDocIdForVerify() {
    // ✅ Use actual Firestore doc id if we found one (MyKad / I-Kad)
    if (_resolvedCardType != null && _resolvedCardType!.trim().isNotEmpty) {
      return _resolvedCardType!.trim();
    }

    final t = widget.cardTitle.trim().toLowerCase();
    if (t.contains('driving')) return 'Driving License';
    if (t.contains('mykad')) return 'MyKad';
    if (t.contains('i-kad')) return 'I-Kad';
    if (t == 'ic') return 'IC';
    return widget.cardTitle.trim();
  }

  /// QR payload 
  String _buildVerificationQrData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '';
    return jsonEncode({
      'type': 'kitaid_verify',
      'kind': 'card',
      'uid': uid,
      'cardId': _cardDocIdForVerify(),
      'v': 1,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // -----------------------
  // Firestore: fetch card
  // -----------------------
  Future<void> _autoFetchCardFromFirestore({required bool fetchImage}) async {
    try {
      setState(() => _loadingImage = fetchImage);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() => _loadingImage = false);
        return;
      }

      final t = widget.cardTitle.trim().toLowerCase();

      final List<String> docCandidates = t.contains('driving')
          ? [
              'Driving License',
              'driving license',
              'Driving Licence',
              'driving licence',
              'driving_license',
              'driving_licence',
              'license',
              'licence',
            ]
          : (t.contains('mykad') || t.contains('i-kad') || t == 'ic')
              ? [
                  // ✅ MyKad / I-Kad variants
                  'MyKad',
                  'mykad',
                  'I-Kad',
                  'i-kad',
                  'IKad',
                  'iKad',
                  'IC',
                  'ic',
                  'mykad card',
                  'ic card',
                ]
              : [t];

      DocumentSnapshot<Map<String, dynamic>>? found;

      for (final docId in docCandidates) {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('cards')
            .doc(docId)
            .get();

        if (doc.exists) {
          found = doc;
          break;
        }
      }

      final data = found?.data();
      final resolvedType = found?.id; // ✅ exact doc id we matched
      final url = fetchImage ? _extractAnyUrl(data) : null;

      if (!mounted) return;
      setState(() {
        _cardData = data;
        _resolvedCardType = resolvedType;
        if (fetchImage) _fetchedImageUrl = url;
        _loadingImage = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch card doc: $e');
      if (!mounted) return;
      setState(() => _loadingImage = false);
    }
  }

  // -----------------------
  // Firestore: favorites
  // -----------------------
  Future<void> _loadFavorite() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
          _loadingFavorite = false;
        });
        return;
      }

      final key = _favoriteKey();
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('favorites')
          .doc(key)
          .get();

      final isFav = doc.data()?['isFavorite'] == true;

      if (!mounted) return;
      setState(() {
        _isFavorite = isFav;
        _loadingFavorite = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load favorite: $e');
      if (!mounted) return;
      setState(() => _loadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _toast('Please log in');
      return;
    }

    final key = _favoriteKey();
    final newValue = !_isFavorite;

    setState(() => _isFavorite = newValue);

    try {
      final ref = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('favorites')
          .doc(key);

      if (newValue) {
        await ref.set({
          'isFavorite': true,
          'type': 'card',
          'cardTitle': widget.cardTitle,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _toast('Added to favorites');
      } else {
        await ref.delete();
        _toast('Removed from favorites');
      }
    } catch (e) {
      debugPrint('❌ Favorite toggle failed: $e');
      if (!mounted) return;
      setState(() => _isFavorite = !newValue);
      _toast('Failed to update favorite');
    }
  }

  // -----------------------
  // PDF export (Share -> Save as PDF)
  // -----------------------
  Future<void> _shareAsPdf({
    required String title,
    required String qrData,
    required List<_DetailItem> details,
    String? networkImageUrl,
    String? assetImagePath,
  }) async {
    try {
      final doc = pw.Document();

      // Card image (optional)
      pw.ImageProvider? cardImg;
      if (networkImageUrl != null && networkImageUrl.trim().isNotEmpty) {
        cardImg = await networkImage(networkImageUrl.trim());
      } else if (assetImagePath != null && assetImagePath.trim().isNotEmpty) {
        final bytes = await rootBundle.load(assetImagePath.trim());
        cardImg = pw.MemoryImage(bytes.buffer.asUint8List());
      }

      // QR image bytes
      final qrPainter = QrPainter(
        data: qrData.isEmpty ? 'not_logged_in' : qrData,
        version: QrVersions.auto,
        gapless: true,
      );
      final ui.Image qrUiImage = await qrPainter.toImage(500);
      final byteData =
          await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
      final qrBytes = byteData!.buffer.asUint8List();
      final qrImg = pw.MemoryImage(qrBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: cardImg == null
                            ? pw.Center(child: pw.Text('No image'))
                            : pw.ClipRRect(
                                horizontalRadius: 10,
                                verticalRadius: 10,
                                child: pw.Center(
                                  child: pw.Image(
                                    cardImg,
                                    fit: pw.BoxFit.contain, // ✅ full card
                                  ),
                                ),
                              ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Container(
                      width: 140,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Image(qrImg),
                    ),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.7),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    for (final d in details)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              d.label,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              d.value.trim().isEmpty ? '-' : d.value.trim(),
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final bytes = await doc.save();

      // ✅ System dialog -> Save as PDF / Print / Share
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: '${title.replaceAll(' ', '_')}_details.pdf',
      );
    } catch (e) {
      debugPrint('❌ PDF export error: $e');
      _toast('PDF export failed');
    }
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final qrData = _buildVerificationQrData();

    final incomingUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final fetchedUrl =
        _fetchedImageUrl != null && _fetchedImageUrl!.trim().isNotEmpty;

    final hasNetworkImage = incomingUrl || fetchedUrl;
    final String? networkUrl = hasNetworkImage
        ? (incomingUrl ? widget.imageUrl!.trim() : _fetchedImageUrl!.trim())
        : null;

    final hasAssetImage =
        widget.imageAsset != null && widget.imageAsset!.trim().isNotEmpty;

    final details = _getDetailsByCardType();

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
            // ================= CARD IMAGE =================
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: _loadingImage
                    ? Container(
                        color: mycolors.bgPrimary,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 26,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (hasNetworkImage && networkUrl != null)
                        ? Image.network(
                            networkUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: mycolors.bgPrimary,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: progress.expectedTotalBytes == null
                                        ? null
                                        : progress.cumulativeBytesLoaded /
                                            (progress.expectedTotalBytes ?? 1),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ CardDetail image failed: $error');
                              return _previewFallback(theme);
                            },
                          )
                        : hasAssetImage
                            ? Image.asset(widget.imageAsset!, fit: BoxFit.cover)
                            : _previewFallback(theme),
              ),
            ),
            const SizedBox(height: 14),

            // ================= QR (POLICE SCAN) =================
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
                  data: qrData.isEmpty ? 'not_logged_in' : qrData,
                  size: 120,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ================= DETAILS TITLE + ACTIONS =================
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final all = details
                            .map((e) => '${e.label}: ${e.value}')
                            .join('\n');
                        await _copyText(all, toastMsg: 'Copied all details');
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      color: mycolors.textPrimary,
                      tooltip: 'Copy all',
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await _shareAsPdf(
                          title: widget.cardTitle,
                          qrData: qrData,
                          details: details,
                          networkImageUrl: networkUrl,
                          assetImagePath: widget.imageAsset,
                        );
                      },
                      icon: const Icon(Icons.ios_share, size: 20),
                      color: mycolors.textPrimary,
                      tooltip: 'Save as PDF',
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _loadingFavorite ? null : _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        size: 22,
                      ),
                      color:
                          _isFavorite ? mycolors.Primary : mycolors.textPrimary,
                      tooltip: 'Favorite',
                    ),
                  ],
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
                children: _buildDetails(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewFallback(ThemeData theme) {
    return Container(
      color: mycolors.bgPrimary,
      alignment: Alignment.center,
      child: Text(
        '${widget.cardTitle} Preview',
        style: theme.textTheme.titleMedium?.copyWith(
          color: mycolors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildDetails(ThemeData theme) {
    final items = _getDetailsByCardType();
    final widgets = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      widgets.add(_detailRow(theme, items[i].label, items[i].value));
      if (i != items.length - 1) widgets.add(const Divider(height: 1));
    }
    return widgets;
  }

  List<_DetailItem> _getDetailsByCardType() {
    final t = widget.cardTitle.trim().toLowerCase();
    final data = _cardData ?? {};

    String pickAny(List<String> keys, String fallback) {
      for (final k in keys) {
        final v = data[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return fallback;
    }

    if (t.contains('mykad') || t.contains('i-kad') || t == 'ic') {
      final cardTypeShown = (_resolvedCardType != null &&
              _resolvedCardType!.trim().isNotEmpty)
          ? _resolvedCardType!.trim()
          : widget.cardTitle.trim();

      return [
        _DetailItem('Card Type', cardTypeShown), // ✅ MyKad or I-Kad
        _DetailItem('Name', pickAny(['name', 'Name'], widget.ownerName)),
        _DetailItem(
          'Date of Birth',
          pickAny(
            ['dob', 'DOB', 'Date of Birth', 'date of birth'],
            widget.ownerDob,
          ),
        ),
        _DetailItem(
          'Nationality',
          pickAny(['nationality', 'Nationality'], widget.ownerCountry),
        ),
        _DetailItem(
          'MyKad No',
          pickAny(
            ['mykadNo', 'mykad_no', 'icNo', 'ic_no'],
            _onlyId(widget.cardIdLabel),
          ),
        ),
        _DetailItem(
          'Location',
          pickAny(['location', 'Location'], ''),
        ),
      ];
    }

    if (t.contains('driving')) {
      return [
        _DetailItem('Name', pickAny(['Name', 'name'], widget.ownerName)),
        _DetailItem('Address', pickAny(['address', 'Address'], '')),
        _DetailItem('Class', pickAny(['class', 'Class'], '')),
        _DetailItem(
          'Identity No',
          pickAny(
            [
              'identity no',
              'identity_no',
              'identityNo',
              'ic',
              'icNo',
              'IC',
              'IC No',
              'IC_No',
            ],
            _onlyId(widget.cardIdLabel),
          ),
        ),
        _DetailItem(
          'Nationality',
          pickAny(['nationality', 'Nationality'], widget.ownerCountry),
        ),
        _DetailItem(
          'Validity',
          pickAny(['validity', 'Validity', 'validFromTo', 'valid_from_to'], ''),
        ),
      ];
    }

    return [
      _DetailItem('Owner', pickAny(['name', 'Name'], widget.ownerName)),
      _DetailItem('Card Type', widget.cardTitle),
      _DetailItem('ID', pickAny(['id', 'ID'], _onlyId(widget.cardIdLabel))),
    ];
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
                fontSize: mysizes.fontMd,
                color: mycolors.textPrimary,
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

  String _onlyId(String text) {
    return text.replaceFirst(RegExp(r'^\s*ID:\s*'), '').trim();
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
