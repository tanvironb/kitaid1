// lib/features/authentication/screen/profile/card_detail_page.dart
import 'package:flutter/material.dart';
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
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  /// Local asset fallback (optional)
  final String? imageAsset;

  /// ✅ Firebase Storage download URL (optional)
  final String? imageUrl;

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  String? _fetchedImageUrl;
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();

    final hasIncomingUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    // If not passed from profile/home, fetch from Firestore
    if (!hasIncomingUrl) {
      _autoFetchImageFromFirestore();
    }
  }

  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.startsWith('http://') || s.startsWith('https://');
  }

  String? _extractAnyUrl(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Try common keys first
    const keysToTry = [
      'license',
      'ic',
      'mykad',
      'imageUrl',
      'url',
      'front',
      'card',
      'photo',
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

  Future<void> _autoFetchImageFromFirestore() async {
    try {
      setState(() => _loadingImage = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() => _loadingImage = false);
        return;
      }

      final t = widget.cardTitle.trim().toLowerCase();

      // Try multiple possible docIds (because sometimes naming differs)
      final List<String> docCandidates = t.contains('driving')
          ? ['driving license', 'driving licence', 'license', 'licence']
          : (t.contains('mykad') || t == 'ic')
              ? ['ic', 'mykad', 'mykad card', 'ic card']
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

      final url = _extractAnyUrl(found?.data());

      if (!mounted) return;
      setState(() {
        _fetchedImageUrl = url;
        _loadingImage = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to fetch card image url: $e');
      if (!mounted) return;
      setState(() => _loadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final qrData =
        'KitaID|${widget.cardTitle}|${widget.cardIdLabel}|${widget.ownerName}|${widget.ownerDob}|${widget.ownerCountry}';

    final incomingUrl =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final fetchedUrl =
        _fetchedImageUrl != null && _fetchedImageUrl!.trim().isNotEmpty;

    final hasNetworkImage = incomingUrl || fetchedUrl;
    final String? networkUrl =
        hasNetworkImage ? (incomingUrl ? widget.imageUrl!.trim() : _fetchedImageUrl!.trim()) : null;

    final hasAssetImage =
        widget.imageAsset != null && widget.imageAsset!.trim().isNotEmpty;

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

            Row(
              children: [
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Favorite (TODO)')),
                    );
                  },
                  icon: const Icon(Icons.star_border),
                  color: mycolors.textPrimary,
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: mycolors.Primary,
                fontWeight: FontWeight.w700,
              ),
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

    if (t == 'mykad' || t == 'ic') {
      return [
        _DetailItem('Name', widget.ownerName),
        _DetailItem('Date of Birth', widget.ownerDob),
        _DetailItem('Nationality', widget.ownerCountry),
        _DetailItem('MyKad No', _onlyId(widget.cardIdLabel)),
      ];
    }

    if (t.contains('driving')) {
      return [
        _DetailItem('Name', widget.ownerName),
        _DetailItem('License Class', 'D / B2'),
        _DetailItem('Expiry Date', '27/10/2030'),
        _DetailItem('Address', 'Kuala Lumpur, Malaysia'),
        _DetailItem('License No', _onlyId(widget.cardIdLabel)),
      ];
    }

    return [
      _DetailItem('Owner', widget.ownerName),
      _DetailItem('Card Type', widget.cardTitle),
      _DetailItem('ID', _onlyId(widget.cardIdLabel)),
    ];
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
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

  String _onlyId(String text) {
    return text.replaceFirst(RegExp(r'^\s*ID:\s*'), '').trim();
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
