// lib/features/authentication/screen/profile/travel_history_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class TravelHistoryPage extends StatelessWidget {
  const TravelHistoryPage({
    super.key,
    required this.uid,
    required this.docId, //"Passport"
  });

  final String uid;
  final String docId;


  DocumentReference<Map<String, dynamic>> _travelDoc() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('docs')
        .doc(docId)
        .collection('travelHistory')
        .doc('travelHistory');
  }

  // --- helpers ---
  String _s(dynamic v) => (v ?? '').toString().trim();


  String _placeFromLine(String line) {
    final parts = line.split('-');
    return parts.isEmpty ? line.trim() : parts.first.trim();
  }


  String _dateFromLine(String line) {
    final parts = line.split('-');
    if (parts.length < 2) return '';
    return parts.last.trim();
  }

  String _flagForPlace(String place) {
    final key = place.trim().toLowerCase();

    // mapping 
    const map = <String, String>{
      'malaysia': 'MY',
      'qatar': 'QA',
      'spain': 'ES',
      'london': 'GB',
      'uk': 'GB',
      'united kingdom': 'GB',
      'england': 'GB',
      'singapore': 'SG',
      'indonesia': 'ID',
      'thailand': 'TH',
      'china': 'CN',
      'japan': 'JP',
      'korea': 'KR',
      'south korea': 'KR',
      'saudi arabia': 'SA',
      'uae': 'AE',
      'united arab emirates': 'AE',
      'turkey': 'TR',
      'france': 'FR',
      'germany': 'DE',
      'italy': 'IT',
      'australia': 'AU',
      'usa': 'US',
      'united states': 'US',
      'canada': 'CA',
      'bangladesh': 'BD',
      'india': 'IN',
      'pakistan': 'PK',
      'egypt': 'EG',
    };

    final iso2 = map[key];
    if (iso2 == null || iso2.length != 2) return '🏳️';

    // Convert "MY" -> 🇲🇾
    final a = iso2.codeUnitAt(0) - 65 + 0x1F1E6;
    final b = iso2.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCode(a) + String.fromCharCode(b);
  }

  List<_TravelItem> _parseTravelFields(Map<String, dynamic> data) {
    // Expect keys like country, country2, country3...
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final items = <_TravelItem>[];
    for (final e in entries) {
      final v = _s(e.value);
      if (v.isEmpty) continue;

      final place = _placeFromLine(v);
      final date = _dateFromLine(v);

      items.add(_TravelItem(
        raw: v,
        place: place.isEmpty ? v : place,
        date: date,
      ));
    }
    return items;
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
          'Travel History',
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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _travelDoc().snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Failed to load travel history.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontSm,
                  ),
                ),
              );
            }

            final doc = snap.data;
            final data = doc?.data() ?? {};

            if (data.isEmpty) {
              return Center(
                child: Text(
                  'No travel history yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontMd,
                  ),
                ),
              );
            }

            final items = _parseTravelFields(data);

            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No travel history yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontMd,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final flag = _flagForPlace(item.place);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mycolors.borderprimary),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.place,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: mycolors.Primary,
                                fontWeight: FontWeight.w800,
                                fontSize: mysizes.fontMd,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.date.isEmpty ? item.raw : item.date,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: mycolors.textPrimary,
                                fontSize: mysizes.fontSm,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _TravelItem {
  final String raw;
  final String place;
  final String date;

  const _TravelItem({
    required this.raw,
    required this.place,
    required this.date,
  });
}
