import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
//import 'package:kitaid1/widgets/kita_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// Simple user model for now.
/// Later you can replace this with data coming from your backend / login.
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

/// Model representing ONE card that belongs to the user.
/// Later: fill this list from backend (IC, passport, license, etc.).
class ProfileCardItem {
  final String title;       // e.g. "MyKad"
  final String idLabel;     // e.g. "ID: 123456-78-9012"
  final String? imageAsset; // optional, big preview

  const ProfileCardItem({
    required this.title,
    required this.idLabel,
    this.imageAsset,
  });
}

/// Model representing ONE document that belongs to the user.
class ProfileDocItem {
  final String title;       // e.g. "Passport Scan"
  final String description; // e.g. "Uploaded on 01/12/2025"

  const ProfileDocItem({
    required this.title,
    required this.description,
  });
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTab = 0; // 0 = Cards, 1 = Docs

  // TODO: When you have backend:
  //  - Replace this dummy user with real data loaded using IC / passport.
  final _UserProfile _user = const _UserProfile(
    name: 'Tanvir',          // <- will come from IC/passport login later
    id: 'A02581787',         // <- IC / passport number or internal ID
    country: 'Bangladesh',
    dateOfBirth: '27/10/2001',
  );

  // ====== DUMMY DATA FOR NOW ======
  // Later: Replace these with data from backend, filtered by _user.id / IC.
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
  // =================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ---------- APP BAR ----------
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

      // ---------- BODY ----------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(mysizes.defaultspace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----- Profile header -----
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================
                  // SECTION 1: Profile + Name + ID
                  // ============================
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

                  // ------ GAP BETWEEN SECTIONS ------
                  const SizedBox(height: 22),

                  // ============================
                  // SECTION 2: Country + DOB
                  // ============================
                  Row(
                    children: [
                      // Country Block
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

                      // DOB Block
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

              // ----- Tabs: Cards / Docs -----
              Row(
                children: [
                  Expanded(
                    child: _SegmentTab(
                      label: 'Cards',
                      selected: _selectedTab == 0,
                      onTap: () {
                        setState(() => _selectedTab = 0);
                      },
                    ),
                  ),
                  const SizedBox(width: mysizes.spacebtwitems),
                  Expanded(
                    child: _SegmentTab(
                      label: 'Docs',
                      selected: _selectedTab == 1,
                      onTap: () {
                        setState(() => _selectedTab = 1);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: mysizes.spacebtwsections),

              // ----- Tab content -----
              if (_selectedTab == 0)
                _CardsSection(
                  cards: _cards,
                )
              else
                _DocsSection(
                  docs: _docs,
                ),
            ],
          ),
        ),
      ),

      // ---------- OFFICIAL KITAID NAVBAR ----------
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 4, // PROFILE / SETTINGS tab
        onTap: (index) {
          if (index == 4) return; // already on this page

          switch (index) {
            case 0: // HOME
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (_) => false);
              break;
            case 1: // CHATBOT
              Navigator.pushNamedAndRemoveUntil(
                  context, '/chatbot', (_) => false);
              break;
            case 2: // SERVICES
              Navigator.pushNamedAndRemoveUntil(
                  context, '/services', (_) => false);
              break;
            case 3: // NOTIFICATIONS
              Navigator.pushNamedAndRemoveUntil(
                  context, '/notifications', (_) => false);
              break;
            case 4: // PROFILE
              Navigator.pushNamedAndRemoveUntil(
                  context, '/profile', (_) => false);
              break;
          }
        },
      ),
    );
  }
}

// ================== SMALL WIDGETS ==================

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
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
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
  const _CardsSection({required this.cards});

  final List<ProfileCardItem> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: mysizes.spacebtwsections,
          ),
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
          _CardTile(card: card, theme: theme),
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
  });

  final ProfileCardItem card;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card preview (image or placeholder)
          AspectRatio(
            aspectRatio: 1.6,
            child: card.imageAsset != null
                ? Image.asset(
                    card.imageAsset!,
                    fit: BoxFit.cover,
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
    );
  }
}

class _DocsSection extends StatelessWidget {
  const _DocsSection({required this.docs});

  final List<ProfileDocItem> docs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: mysizes.spacebtwsections,
          ),
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
              onTap: () {
                // TODO: Open document viewer later
              },
            ),
          ),
          const SizedBox(height: mysizes.spacebtwitems),
        ],
      ],
    );
  }
}
