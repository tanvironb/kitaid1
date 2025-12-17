// lib/features/authentication/screen/profile/card_detail_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CardDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Later you can replace this with a secure token from backend.
    final qrData =
        'KitaID|$cardTitle|$cardIdLabel|$ownerName|$ownerDob|$ownerCountry';

    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasAssetImage = imageAsset != null && imageAsset!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ✅ Top bar ONLY: back + done
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
                child: hasNetworkImage
                    ? Image.network(
                        imageUrl!,
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
                          return Container(
                            color: mycolors.bgPrimary,
                            alignment: Alignment.center,
                            child: Text(
                              '$cardTitle Preview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: mycolors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      )
                    : hasAssetImage
                        ? Image.asset(imageAsset!, fit: BoxFit.cover)
                        : Container(
                            color: mycolors.bgPrimary,
                            alignment: Alignment.center,
                            child: Text(
                              '$cardTitle Preview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: mycolors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 14),

            // ✅ Share + Favorite ABOVE QR (NOT in top bar)
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: implement sharing (later: share_plus, share QR image/text)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share (TODO)')),
                    );
                  },
                  icon: const Icon(Icons.ios_share),
                  color: mycolors.textPrimary,
                ),
                IconButton(
                  onPressed: () {
                    // TODO: save as favorite (later: store in backend/local)
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

            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: mycolors.Primary,
                fontWeight: FontWeight.w700,
              ),
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

  // ================= DETAILS BY CARD TYPE =================

  List<Widget> _buildDetails(ThemeData theme) {
    final items = _getDetailsByCardType();

    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(_detailRow(theme, item.label, item.value));
      if (i != items.length - 1) {
        widgets.add(const Divider(height: 1));
      }
    }
    return widgets;
  }

  List<_DetailItem> _getDetailsByCardType() {
    if (cardTitle == 'MyKad' || cardTitle == 'IC') {
      return [
        _DetailItem('Name', ownerName),
        _DetailItem('Date of Birth', ownerDob),
        _DetailItem('Nationality', ownerCountry),
        _DetailItem('MyKad No', _onlyId(cardIdLabel)),
      ];
    }

    if (cardTitle == 'Driving License') {
      return [
        _DetailItem('Name', ownerName),
        _DetailItem('License Class', 'D / B2'), // dummy (replace later)
        _DetailItem('Expiry Date', '27/10/2030'), // dummy
        _DetailItem('Address', 'Kuala Lumpur, Malaysia'), // dummy
        _DetailItem('License No', _onlyId(cardIdLabel)),
      ];
    }

    // Fallback for future cards
    return [
      _DetailItem('Owner', ownerName),
      _DetailItem('Card Type', cardTitle),
      _DetailItem('ID', _onlyId(cardIdLabel)),
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
    // "ID: 123456-78-9012" -> "123456-78-9012"
    return text.replaceFirst(RegExp(r'^\s*ID:\s*'), '').trim();
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
