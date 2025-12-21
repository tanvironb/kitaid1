// lib/features/authentication/screen/profile/card_detail_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ✅ Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // These are still accepted (fallback), but page will fetch from Firestore too.
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  /// Local asset fallback (optional)
  final String? imageAsset;

  /// Firebase Storage download URL (optional)
  final String? imageUrl;

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  String? _fetchedImageUrl;
  bool _loadingImage = false;

  /// ✅ store whole card document so details can be shown
  Map<String, dynamic>? _cardData;

  /// ✅ favorites state (stored in Firestore)
  bool _isFavorite = false;
  bool _loadingFavorite = true;

  @override
  void initState() {
    super.initState();

    final hasIncomingUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    // Always fetch details; fetch image only if not passed in.
    _autoFetchCardFromFirestore(fetchImage: !hasIncomingUrl);

    // Load favorite state
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

    // Try common keys first (case variants included)
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
      'license',
      'licence',
      'drivingLicense',
      'driving_license',
    ];

    for (final k in keysToTry) {
      final v = data[k]?.toString();
      if (_looksLikeUrl(v)) return v!.trim();
    }

    // Fallback: scan all values, pick first that looks like a URL
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

  /// Stable key for favorites document id
  String _favoriteKey() {
    final t = widget.cardTitle.trim().toLowerCase();
    if (t.contains('driving')) return 'driving_license';
    if (t == 'mykad' || t == 'ic') return 'ic';
    return t.replaceAll(RegExp(r'\s+'), '_');
  }

  /// ✅ stable card docId stored inside QR
  String _cardDocIdForVerify() {
    final t = widget.cardTitle.trim().toLowerCase();

    // ✅ Make Driving License QR different from IC QR
    if (t.contains('driving')) return 'Driving License'; // matches your Firestore doc id

    // ✅ IC/MyKad QR
    if (t == 'mykad' || t == 'ic') return 'IC';

    return widget.cardTitle.trim();
  }

  /// ✅ build secure QR payload (NO personal info)
  String _buildVerificationQrData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return ''; // user not logged in
    return jsonEncode({
      'type': 'kitaid_verify',
      'uid': uid,
      'cardId': _cardDocIdForVerify(),
      'v': 1,
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

      // Try multiple possible docIds (because sometimes naming differs)
      final List<String> docCandidates = t.contains('driving')
          ? [
              'Driving License', // ✅ matches your screenshot doc id
              'driving license',
              'Driving Licence',
              'driving licence',
              'driving_license',
              'driving_licence',
              'license',
              'licence',
            ]
          : (t.contains('mykad') || t == 'ic')
              ? [
                  'ic',
                  'IC',
                  'mykad',
                  'MyKad',
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
      final url = fetchImage ? _extractAnyUrl(data) : null;

      if (!mounted) return;
      setState(() {
        _cardData = data; // ✅ store details
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

    // Optimistic UI
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
      setState(() => _isFavorite = !newValue); // rollback
      _toast('Failed to update favorite');
    }
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ QR payload for police to scan (owner should not open verification)
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
                aspectRatio: 1.8,
                child: _loadingImage
                    ? Container(
                        color: mycolors.bgPrimary,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : hasNetworkImage && networkUrl != null
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
                  onPressed: () async {
                    final all =
                        details.map((e) => '${e.label}: ${e.value}').join('\n');
                    await _copyText(all, toastMsg: 'Copied for sharing');
                  },
                  icon: const Icon(Icons.ios_share),
                  color: mycolors.textPrimary,
                  tooltip: 'Share',
                ),
                IconButton(
                  onPressed: _loadingFavorite ? null : _toggleFavorite,
                  icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
                  color: _isFavorite ? mycolors.Primary : mycolors.textPrimary,
                  tooltip: 'Favorite',
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ================= QR ONLY (POLICE SCAN) =================
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

            // ================= DETAILS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: mycolors.Primary,
                    fontWeight: FontWeight.w700,
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

    // ✅ helper: try multiple keys, return first non-empty
    String pickAny(List<String> keys, String fallback) {
      for (final k in keys) {
        final v = data[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return fallback;
    }

    if (t == 'mykad' || t == 'ic') {
      return [
        _DetailItem('Name', pickAny(['name', 'Name'], widget.ownerName)),
        _DetailItem('Date of Birth', pickAny(['dob', 'DOB'], widget.ownerDob)),
        _DetailItem('Nationality',
            pickAny(['nationality', 'Nationality'], widget.ownerCountry)),
        _DetailItem('MyKad No',
            pickAny(['mykadNo', 'mykad_no', 'icNo', 'ic_no'], _onlyId(widget.cardIdLabel))),
      ];
    }

    // ✅ Driving License fields EXACTLY like Firestore screenshot
    if (t.contains('driving')) {
      return [
        _DetailItem('Name', pickAny(['Name', 'name'], widget.ownerName)),
        _DetailItem(
          'Address',
          pickAny(['address', 'Address'], ''),
        ),
        _DetailItem(
          'Class',
          pickAny(['class', 'Class'], ''),
        ),
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
          pickAny(
            ['validity', 'Validity', 'validFromTo', 'valid_from_to'],
            '',
          ),
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
                color: mycolors.textPrimary,
              ),
            ),
            Expanded(
              child: Text(
                displayValue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
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
