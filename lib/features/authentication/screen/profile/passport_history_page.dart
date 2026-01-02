import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class PassportHistoryPage extends StatelessWidget {
  const PassportHistoryPage({
    super.key,
    required this.uid,
    required this.docId, 
  });

  final String uid;
  final String docId;


  CollectionReference<Map<String, dynamic>> _col() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('docs')
        .doc(docId)
        .collection('passporthistory');
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  String _getLoose(Map<String, dynamic> map, List<String> keys) {
    String norm(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final normalized = <String, dynamic>{};
    for (final e in map.entries) {
      normalized[norm(e.key.toString())] = e.value;
    }
    for (final k in keys) {
      final v = normalized[norm(k)];
      final out = _s(v);
      if (out.isNotEmpty) return out;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: mycolors.textPrimary,
        title: Text(
          'Passport History',
          style: theme.textTheme.titleMedium?.copyWith(
            color: mycolors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: mysizes.fontMd,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(mysizes.defaultspace),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
         
          stream: _col().snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  'Failed to load passport history.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontSm,
                  ),
                ),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No passport history yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontMd,
                  ),
                ),
              );
            }

   
            docs.sort((a, b) => a.id.compareTo(b.id));

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final data = docs[i].data();

                final passportNo = _getLoose(data, const [
                  'passportno',
                  'passport no',
                  'passport_no',
                  'passportNo',
                ]);

                final expiry = _getLoose(data, const [
                  'dateofexpiery', 
                  'dateofexpiry',
                  'date of expiry',
                  'expiry',
                  'dateOfExpiry',
                ]);

                final status = _getLoose(data, const [
                  'status',
                ]);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mycolors.borderprimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Old Passport No',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mycolors.Primary,
                          fontWeight: FontWeight.w800,
                          fontSize: mysizes.fontMd,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passportNo.isEmpty ? '-' : passportNo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mycolors.textPrimary,
                          fontSize: mysizes.fontSm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: mycolors.borderprimary),
                      const SizedBox(height: 12),

                      if (status.isNotEmpty) _infoRow(theme, 'Status', status),
                      if (expiry.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _infoRow(theme, 'Date of Expiry', expiry),
                      ],
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

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mycolors.textPrimary,
              fontSize: mysizes.fontSm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mycolors.textPrimary,
              fontSize: mysizes.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
