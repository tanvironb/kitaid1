import 'package:flutter/material.dart';
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

class _UserProfile {
  final String name;
  final String id;
  final String country;
  final String dateOfBirth;

  const _UserProfile({
    required this.name,
    required this.id,
    required this.country,
    required this.dateOfBirth,
  });
}

class ProfileCardItem {
  final String title;
  final String idLabel;
  final String? imageAsset;

  const ProfileCardItem({
    required this.title,
    required this.idLabel,
    this.imageAsset,
  });
}

class ProfileDocItem {
  final String title;
  final String description;

  const ProfileDocItem({
    required this.title,
    required this.description,
  });
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0;

  final _UserProfile _user = const _UserProfile(
    name: 'Tanvir',
    id: 'A02581787',
    country: 'Bangladesh',
    dateOfBirth: '27/10/2001',
  );

  final List<ProfileCardItem> _cards = const [
    ProfileCardItem(
      title: 'MyKad',
      idLabel: 'ID: 123456-78-9012',
      imageAsset: null, // e.g. 'assets/cards/mykad.png'
    ),
    ProfileCardItem(
      title: 'Driving License',
      idLabel: 'ID: D-9087654321',
      imageAsset: null,
    ),
  ];

  final List<ProfileDocItem> _docs = const [
    ProfileDocItem(
      title: 'Passport Scan',
      description: 'Uploaded on 01/12/2025',
    ),
    ProfileDocItem(
      title: 'Student ID PDF',
      description: 'Uploaded on 15/11/2025',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: SingleChildScrollView(
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
                            _user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: mycolors.Primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${_user.id}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mycolors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {},
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
                            _user.country,
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
                            _user.dateOfBirth,
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
                _CardsSection(
                  cards: _cards,
                  onCardTap: (card) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardDetailPage(
                          cardTitle: card.title,
                          cardIdLabel: card.idLabel,
                          imageAsset: card.imageAsset,
                          ownerName: _user.name,
                          ownerDob: _user.dateOfBirth,
                          ownerCountry: _user.country,
                        ),
                      ),
                    );
                  },
                )
              else
                _DocsSection(
                  docs: _docs,
                  onDocTap: (doc) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocDetailPage(
                          docTitle: doc.title,
                          docDescription: doc.description,
                          ownerName: _user.name,
                          ownerDob: _user.dateOfBirth,
                          ownerCountry: _user.country,
                          previewAsset: null, // later: set an image preview asset
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
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

class _CardsSection extends StatelessWidget {
  const _CardsSection({
    required this.cards,
    required this.onCardTap,
  });

  final List<ProfileCardItem> cards;
  final void Function(ProfileCardItem card) onCardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cards.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final card in cards) ...[
          _CardTile(
            card: card,
            theme: theme,
            onTap: () => onCardTap(card),
          ),
          const SizedBox(height: mysizes.spacebtwitems),
        ],
      ],
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

// ✅ UPDATED DOCS SECTION (NOW TAPPABLE)
class _DocsSection extends StatelessWidget {
  const _DocsSection({
    required this.docs,
    required this.onDocTap,
  });

  final List<ProfileDocItem> docs;
  final void Function(ProfileDocItem doc) onDocTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return Column(
      children: [
        for (final doc in docs) ...[
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
              onTap: () => onDocTap(doc), // ✅ NOW OPENS DETAILS
            ),
          ),
          const SizedBox(height: mysizes.spacebtwitems),
        ],
      ],
    );
  }
}
