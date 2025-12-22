// lib/features/authentication/screen/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/features/authentication/screen/profile/card_detail_page.dart';
import 'package:kitaid1/features/authentication/screen/profile/doc_detail_page.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class ProfileCardItem {
  final String id; // Firestore doc id
  final String title;
  final String idLabel;

  /// Network image url from Firestore (Firebase Storage downloadURL)
  final String? imageUrl;

  /// Local asset fallback (optional)
  final String? imageAsset;

  const ProfileCardItem({
    required this.id,
    required this.title,
    required this.idLabel,
    this.imageUrl,
    this.imageAsset,
  });
}

class ProfileDocItem {
  final String id;
  final String title;
  final String description;

  /// Passport cover / doc preview URL
  final String? previewUrl;

  const ProfileDocItem({
    required this.id,
    required this.title,
    required this.description,
    this.previewUrl,
  });
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.startsWith('http://') || s.startsWith('https://');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _user?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: uid == null
            ? Padding(
                padding: const EdgeInsets.all(mysizes.defaultspace),
                child: Center(
                  child: Text(
                    'Please log in to view your profile.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mycolors.textPrimary,
                    ),
                  ),
                ),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snap.data?.data() ?? {};

                  final name = (data['Name'] ?? '').toString().trim();
                  final ic = (data['IC No'] ?? '').toString().trim();
                  final phone = (data['Phone No'] ?? '').toString().trim();

                  // fallback fields
                  final fallbackNationality =
                      (data['Nationality'] ?? data['Country'] ?? '')
                          .toString()
                          .trim();
                  final fallbackDob =
                      (data['dob'] ?? data['DOB'] ?? '').toString().trim();

                  // profile photo url from Firestore
                  final firestorePhotoUrl =
                      (data['photoUrl'] ?? '').toString().trim();

                  // fallback: FirebaseAuth photoURL
                  final authPhotoUrl = _user?.photoURL?.trim() ?? '';

                  final resolvedPhotoUrl = _looksLikeUrl(firestorePhotoUrl)
                      ? firestorePhotoUrl
                      : (_looksLikeUrl(authPhotoUrl) ? authPhotoUrl : '');

                  final displayName = name.isNotEmpty ? name : 'User';
                  final displayId = ic.isNotEmpty ? ic : uid;

                  // ✅ Read DOB + Nationality from cards collection (IC/MyKad doc)
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(uid)
                        .collection('cards')
                        .snapshots(),
                    builder: (context, cardSnap) {
                      final cardDocs = cardSnap.data?.docs ?? [];

                      DocumentSnapshot<Map<String, dynamic>>? icDoc;
                      for (final d in cardDocs) {
                        final idLower = d.id.toLowerCase().trim();
                        if (idLower == 'ic' ||
                            idLower == 'mykad' ||
                            idLower.contains('mykad')) {
                          icDoc = d;
                          break;
                        }
                        if (d.id == 'IC') {
                          icDoc = d;
                          break;
                        }
                      }

                      final cardData = icDoc?.data() ?? {};

                      final nationalityFromCard =
                          _pick(cardData, ['nationality', 'Nationality'], '');
                      final dobFromCard =
                          _pick(cardData, ['dob', 'DOB', 'dateOfBirth'], '');

                      final displayNationality = (nationalityFromCard.isNotEmpty
                              ? nationalityFromCard
                              : fallbackNationality)
                          .trim();
                      final displayDob =
                          (dobFromCard.isNotEmpty ? dobFromCard : fallbackDob)
                              .trim();

                      final showNationality =
                          displayNationality.isNotEmpty ? displayNationality : '-';
                      final showDob = displayDob.isNotEmpty ? displayDob : '-';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(mysizes.defaultspace),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== HEADER =====
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          theme.colorScheme.secondaryContainer,
                                      backgroundImage: resolvedPhotoUrl.isNotEmpty
                                          ? NetworkImage(resolvedPhotoUrl)
                                          : const AssetImage(
                                              'assets/images/profile_placeholder.png',
                                            ) as ImageProvider,
                                      child: resolvedPhotoUrl.isNotEmpty
                                          ? null
                                          : Icon(
                                              Icons.person,
                                              color: theme.colorScheme
                                                  .onSecondaryContainer,
                                              size: 26,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: mycolors.Primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: mysizes.fontMd,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'IC: $displayId',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: mycolors.textPrimary,
                                            fontSize: mysizes.fontSm,
                                          ),
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Phone: $phone',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: mycolors.textPrimary,
                                              fontSize: mysizes.fontSm,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nationality',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: mysizes.fontSm,
                                            color: mycolors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          showNationality,
                                          style:
                                              theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: mycolors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 40),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date of Birth',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: mysizes.fontSm,
                                            color: mycolors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          showDob,
                                          style:
                                              theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            color: mycolors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: mysizes.spacebtwsections),

                            // ===== TABS =====
                            Row(
                              children: [
                                Expanded(
                                  child: _SegmentTab(
                                    label: 'Cards',
                                    selected: _selectedTab == 0,
                                    onTap: () =>
                                        setState(() => _selectedTab = 0),
                                  ),
                                ),
                                const SizedBox(width: mysizes.spacebtwitems),
                                Expanded(
                                  child: _SegmentTab(
                                    label: 'Docs',
                                    selected: _selectedTab == 1,
                                    onTap: () =>
                                        setState(() => _selectedTab = 1),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: mysizes.spacebtwsections),

                            // ===== CONTENT =====
                            if (_selectedTab == 0)
                              _CardsFromFirestore(
                                uid: uid,
                                ownerName: displayName,
                                ownerDob: showDob,
                                ownerCountry: showNationality,
                              )
                            else
                              _DocsFromFirestore(
                                uid: uid,
                                ownerName: displayName,
                                ownerDob: showDob,
                                ownerCountry: showNationality,
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),

      bottomNavigationBar: KitaBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;

          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              break;
            case 1:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/chatbot', (_) => false);
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/services', (_) => false);
              break;
            case 3:
              Navigator.pushNamedAndRemoveUntil(
                  context, '/notifications', (_) => false);
              break;
            case 4:
              Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
              break;
          }
        },
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? mycolors.Primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: mysizes.fontMd,
            color: selected ? Colors.white : mycolors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// CARDS FROM FIRESTORE
/// ---------------------------
class _CardsFromFirestore extends StatelessWidget {
  const _CardsFromFirestore({
    required this.uid,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
  });

  final String uid;
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.startsWith('http://') || s.startsWith('https://');
  }

  String? _pickImageUrl(Map<String, dynamic> data) {
    String? asString(dynamic v) => v?.toString().trim();

    const keys = [
      'imageUrl',
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
    ];

    for (final k in keys) {
      final v = asString(data[k]);
      if (_looksLikeUrl(v)) return v!;
    }

    for (final e in data.entries) {
      final v = asString(e.value);
      if (_looksLikeUrl(v)) return v!;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('cards')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: mysizes.spacebtwsections),
              child: Text(
                'No cards yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                  fontSize: mysizes.fontMd,
                ),
              ),
            ),
          );
        }

        final cards = docs.map((d) {
          final data = d.data();
          final title = (data['title'] ?? d.id).toString().trim();
          final rawIdLabel = (data['idLabel'] ?? '').toString().trim();
          final idLabel = rawIdLabel.isNotEmpty ? rawIdLabel : 'ID: -';

          final imageUrl = _pickImageUrl(data);

          return ProfileCardItem(
            id: d.id,
            title: title,
            idLabel: idLabel,
            imageUrl: imageUrl,
            imageAsset: null,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final card in cards) ...[
              _CardTile(
                card: card,
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailPage(
                        cardTitle: card.title,
                        cardIdLabel: card.idLabel,
                        imageAsset: card.imageAsset,
                        imageUrl: card.imageUrl,
                        ownerName: ownerName,
                        ownerDob: ownerDob,
                        ownerCountry: ownerCountry,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: mysizes.spacebtwitems),
            ],
          ],
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.theme,
    required this.onTap,
  });

  final ProfileCardItem card;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage =
        card.imageUrl != null && card.imageUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: hasNetworkImage
                  ? Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: mycolors.bgPrimary,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: mycolors.bgPrimary,
                          alignment: Alignment.center,
                          child: Text(
                            '${card.title} Preview',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mycolors.textPrimary,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: mycolors.bgPrimary,
                      alignment: Alignment.center,
                      child: Text(
                        '${card.title} Preview',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mycolors.textPrimary,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      card.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mycolors.textPrimary,
                        fontSize: mysizes.fontSm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------
/// DOCS FROM FIRESTORE
/// ✅ Big cards like Cards (Passport cover as preview)
/// ---------------------------
class _DocsFromFirestore extends StatelessWidget {
  const _DocsFromFirestore({
    required this.uid,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerCountry,
  });

  final String uid;
  final String ownerName;
  final String ownerDob;
  final String ownerCountry;

  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.startsWith('http://') || s.startsWith('https://');
  }

  String? _pickPreviewUrl(String docId, Map<String, dynamic> data) {
    // Users/{uid}/docs/Passport  field: "Passport" = downloadURL
    final preferredKeys = <String>[
      docId, // "Passport"
      docId.toLowerCase(), // "passport"
      'Passport',
      'passport',
      'previewUrl',
      'imageUrl',
      'url',
      'coverUrl',
    ];

    final direct = data['Passport']?.toString().trim();
      if (_looksLikeUrl(direct)) return direct!;

    // fallback: any url-like field
    for (final k in preferredKeys) {
      final v = data[k]?.toString().trim();
      if (_looksLikeUrl(v)) return v!;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('docs')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: mysizes.spacebtwsections),
              child: Text(
                'No documents yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                  fontSize: mysizes.fontMd,
                ),
              ),
            ),
          );
        }

        final list = docs.map((d) {
          final data = d.data();
          final previewUrl = _pickPreviewUrl(d.id, data);

          return ProfileDocItem(
            id: d.id,
            title: (data['title'] ?? d.id).toString().trim(),
            description: (data['description'] ?? '').toString().trim(),
            previewUrl: previewUrl,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final doc in list) ...[
              _DocTileBig(
                doc: doc,
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocDetailPage(
                        uid: uid, 
                        docId: doc.id,                 
                        docTitle: doc.title,
                        docDescription: doc.description.isEmpty ? 'Active' : doc.description,
                        ownerName: ownerName,
                        ownerDob: ownerDob,
                        ownerCountry: ownerCountry,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: mysizes.spacebtwitems),
            ],
          ],
        );
      },
    );
  }
}

/// ✅ Big Doc card (same style as Cards)
class _DocTileBig extends StatelessWidget {
  const _DocTileBig({
    required this.doc,
    required this.theme,
    required this.onTap,
  });

  final ProfileDocItem doc;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage =
        doc.previewUrl != null && doc.previewUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: hasNetworkImage
                  ? Image.network(
                      doc.previewUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: mycolors.bgPrimary,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: mycolors.bgPrimary,
                          alignment: Alignment.center,
                          child: Text(
                            '${doc.title} Preview',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mycolors.textPrimary,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: mycolors.bgPrimary,
                      alignment: Alignment.center,
                      child: Text(
                        '${doc.title} Preview',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mycolors.textPrimary,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      doc.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mycolors.textPrimary,
                        fontSize: mysizes.fontSm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
