// lib/features/profile/doc_detail_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DocDetailPage extends StatelessWidget {
  const DocDetailPage({
    super.key,
    required this.docTitle,
    required this.docDescription,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
    this.previewAsset, // optional image preview (passport cover, pdf thumbnail, etc.)
  });

  final String docTitle;
  final String docDescription;
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;
  final String? previewAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Later replace with backend token / doc-id
    final qrData = 'KitaID|DOC|$docTitle|$docDescription|$ownerName|$ownerDob|$ownerCountry';

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
            // ================= PREVIEW =================
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.25,
                child: previewAsset != null
                    ? Image.asset(previewAsset!, fit: BoxFit.cover)
                    : Container(
                        color: mycolors.bgPrimary,
                        alignment: Alignment.center,
                        child: Text(
                          '$docTitle Preview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: mycolors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // ✅ Share + Favorite ABOVE QR (like your reference)
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

  // ========= DETAILS (different fields by docTitle) =========
  List<Widget> _buildDetails(ThemeData theme) {
    final items = _getDetailsByDocType();

    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      widgets.add(_detailRow(theme, items[i].label, items[i].value));
      if (i != items.length - 1) widgets.add(const Divider(height: 1));
    }
    return widgets;
  }

  List<_DetailItem> _getDetailsByDocType() {
    if (docTitle == 'Passport Scan') {
      return [
        _DetailItem('Name', ownerName),
        _DetailItem('Date of Birth', ownerDob),
        _DetailItem('Nationality', ownerCountry),
        _DetailItem('Passport No', 'MY7856332'), // dummy for now
        _DetailItem('Expiry Date', '30/12/2030'), // dummy
        _DetailItem('Status', docDescription),
      ];
    }

    if (docTitle == 'Student ID PDF') {
      return [
        _DetailItem('Name', ownerName),
        _DetailItem('University', 'IIUM'), // dummy
        _DetailItem('Student ID', 'STU-2025-00123'), // dummy
        _DetailItem('Programme', 'Information Technology'), // dummy
        _DetailItem('Status', docDescription),
      ];
    }

    return [
      _DetailItem('Owner', ownerName),
      _DetailItem('Document', docTitle),
      _DetailItem('Status', docDescription),
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
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
