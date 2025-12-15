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
  final String id;
  final String title;
  final String idLabel;
  final String? imageAsset;

  const ProfileCardItem({
    required this.id,
    required this.title,
    required this.idLabel,
    this.imageAsset,
  });
}

class ProfileDocItem {
  final String id;
  final String title;
  final String description;

  const ProfileDocItem({
    required this.id,
    required this.title,
    required this.description,
  });
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

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

                  // Optional fields if you add later in Firestore:
                  final country = (data['Country'] ?? '').toString().trim();
                  final dob = (data['DOB'] ?? '').toString().trim();

                  final displayName = name.isNotEmpty ? name : 'User';
                  final displayId = ic.isNotEmpty ? ic : uid;

                  // show small text if not yet stored
                  final displayCountry = country.isNotEmpty ? country : '-';
                  final displayDob = dob.isNotEmpty ? dob : '-';

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
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundImage: AssetImage(
                                    'assets/images/profile_placeholder.png',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: mycolors.Primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'IC: $displayId',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: mycolors.textPrimary,
                                      ),
                                    ),
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Phone: $phone',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: mycolors.textPrimary,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Country',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: mycolors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      displayCountry,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: mycolors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 40),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date of Birth',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: mycolors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      displayDob,
                                      style: theme.textTheme.bodySmall?.copyWith(
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
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                            ),
                            const SizedBox(width: mysizes.spacebtwitems),
                            Expanded(
                              child: _SegmentTab(
                                label: 'Docs',
                                selected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
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
                            ownerDob: displayDob,
                            ownerCountry: displayCountry,
                          )
                        else
                          _DocsFromFirestore(
                            uid: uid,
                            ownerName: displayName,
                            ownerDob: displayDob,
                            ownerCountry: displayCountry,
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),

      // ===== OFFICIAL KITAID NAVBAR =====
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;

          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              break;
            case 1:
              Navigator.pushNamedAndRemoveUntil(context, '/chatbot', (_) => false);
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(context, '/services', (_) => false);
              break;
            case 3:
              Navigator.pushNamedAndRemoveUntil(context, '/notifications', (_) => false);
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? mycolors.Primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : mycolors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// CARDS FROM FIRESTORE
/// Path: Users/{uid}/cards
/// Fields expected:
/// - title (String)
/// - idLabel (String)
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
              padding: const EdgeInsets.symmetric(vertical: mysizes.spacebtwsections),
              child: Text(
                'No cards yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                ),
              ),
            ),
          );
        }

        final cards = docs.map((d) {
          final data = d.data();
          return ProfileCardItem(
            id: d.id,
            title: (data['title'] ?? d.id).toString(),
            idLabel: (data['idLabel'] ?? '').toString(),
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
              child: card.imageAsset != null
                  ? Image.asset(card.imageAsset!, fit: BoxFit.cover)
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mycolors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.idLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mycolors.textPrimary,
                    ),
                  ),
                ],
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
/// Path: Users/{uid}/docs
/// Fields expected:
/// - title (String)
/// - description (String)
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
              padding: const EdgeInsets.symmetric(vertical: mysizes.spacebtwsections),
              child: Text(
                'No documents yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                ),
              ),
            ),
          );
        }

        final list = docs.map((d) {
          final data = d.data();
          return ProfileDocItem(
            id: d.id,
            title: (data['title'] ?? d.id).toString(),
            description: (data['description'] ?? '').toString(),
          );
        }).toList();

        return Column(
          children: [
            for (final doc in list) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    doc.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mycolors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    doc.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mycolors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocDetailPage(
                          docTitle: doc.title,
                          docDescription: doc.description,
                          ownerName: ownerName,
                          ownerDob: ownerDob,
                          ownerCountry: ownerCountry,
                          previewAsset: null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: mysizes.spacebtwitems),
            ],
          ],
        );
      },
    );
  }
}
