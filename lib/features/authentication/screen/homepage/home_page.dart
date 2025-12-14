import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:url_launcher/url_launcher.dart';

/// DATA LAYERS / HOOK POINTS
/// 
/// ProfileRepository is a thin interface the future Profile page can control.
/// Replace the dummy implementation with your real one later (e.g., Firebase).
class ProfileRepository extends ChangeNotifier {
  static final ProfileRepository instance = ProfileRepository._();
  ProfileRepository._();

  // Nullable until the user logs in & profile loads.
  UserProfile? _profile;
  List<UserCard> _cards = const [];

  UserProfile? get profile => _profile;
  List<UserCard> get cards => _cards;

  // Call these from your real profile flow once ready:
  void setProfile(UserProfile? p) {
    _profile = p;
    notifyListeners();
  }

  void setCards(List<UserCard> list) {
    _cards = list;
    notifyListeners();
  }
}

class UserProfile {
  final String uid;
  final String? displayName; // null until available
  final String? photoUrl; // null = show default avatar
  const UserProfile({required this.uid, this.displayName, this.photoUrl});
}

class UserCard {
  final String id;
  final String title; // e.g., "MyKad", "Passport", "Driver's License"
  final IconData? icon; // fallback icon until you plug logos
  final String? assetLogo; // when you have a logo asset
  const UserCard({
    required this.id,
    required this.title,
    this.icon,
    this.assetLogo,
  });
}

/// RecentServicesStore keeps lightweight “recently browsed” services.
/// You’ll call RecentServicesStore.recordBrowse(...) from your Services pages.
/// Here we keep it in-memory for simplicity; swap to SharedPreferences or Firestore later.
class RecentServicesStore extends ChangeNotifier {
  static final RecentServicesStore instance = RecentServicesStore._();
  RecentServicesStore._();

  final int _limit = 10;
  final List<ServiceRef> _recent = [];

  List<ServiceRef> get recent => List.unmodifiable(_recent);

  void recordBrowse(ServiceRef service) {
    _recent.removeWhere((s) => s.id == service.id);
    _recent.insert(0, service);
    if (_recent.length > _limit) _recent.removeLast();
    notifyListeners();
  }
}

class ServiceRef {
  final String id; // stable id, e.g., "jpj", "immigration"
  final String name; // display name
  const ServiceRef(this.id, this.name);
}

/// Emergency link model
class EmergencyLink {
  final String id;
  final String name;
  final String phone; // non-null
  final String? url; // optional
  final String? asset;
  final IconData? icon;

  const EmergencyLink({
    required this.id,
    required this.name,
    required this.phone,
    this.url,
    this.asset,
    this.icon,
  });
}

/// --------------------------
/// HOME PAGE
/// --------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Example emergency shortcuts — replace URLs/logos later.
  final List<EmergencyLink> _emergency = const [
    EmergencyLink(
      id: 'jpj',
      name: 'JPJ',
      icon: Icons.directions_car_filled_outlined,
      phone: '03-8000 8000',
      url: 'https://www.jpj.gov.my/',
    ),
    EmergencyLink(
      id: 'immigration',
      name: 'Immigration',
      phone: '03-8000 8000',
      url: 'https://www.imi.gov.my/',
    ),
    EmergencyLink(
      id: 'hkl',
      name: 'HKL',
      icon: Icons.local_hospital_outlined,
      phone: '03-2615 5555',
      url: 'https://hkl.moh.gov.my/',
    ),
    EmergencyLink(
      id: 'ambulance',
      name: 'Ambulance',
      icon: Icons.medical_services_outlined,
      phone: '999',
      url: 'https://www.malaysia.gov.my/portal/content/30131',
    ),
    EmergencyLink(
      id: 'police',
      name: 'Police',
      icon: Icons.local_police_outlined,
      phone: '999',
      url: 'https://www.rmp.gov.my/',
    ),
    EmergencyLink(
      id: 'fire-Service',
      name: 'Fire-Service',
      icon: Icons.local_fire_department_outlined,
      phone: '999',
      url: 'https://www.bomba.gov.my/',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          // Rebuild when profile or recents change.
          animation: Listenable.merge([
            ProfileRepository.instance,
            RecentServicesStore.instance,
          ]),
          builder: (context, _) {
            final profile = ProfileRepository.instance.profile;
            final cards = ProfileRepository.instance.cards;
            final recents = RecentServicesStore.instance.recent;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -----------------------
                      // HEADER: Avatar + Name
                      // -----------------------
                      Row(
                        children: [
                          // Avatar → Profile page
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: scheme.secondaryContainer,
                              backgroundImage:
                                  (profile?.photoUrl?.isNotEmpty ?? false)
                                      ? NetworkImage(profile!.photoUrl!)
                                      : null,
                              child: (profile?.photoUrl?.isNotEmpty ?? false)
                                  ? null
                                  : Icon(
                                      Icons.person,
                                      color: scheme.onSecondaryContainer,
                                      size: 28,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi ${profile?.displayName?.trim().isNotEmpty == true ? profile!.displayName!.trim() : "there"}',
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: mycolors.Primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // -----------------------
                      // MY CARDS (from Profile)
                      // + See all → Profile page
                      // -----------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Cards',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: mycolors.textHeading,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (profile == null || cards.isEmpty) ...[
                        _EmptyStrip(
                          icon: Icons.credit_card,
                          message: profile == null
                              ? 'Log in & set up your profile to see your cards here.'
                              : 'No cards yet. Add cards in Profile and they’ll show here.',
                        ),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.6,
                          ),
                          itemCount: cards.length,
                          itemBuilder: (context, i) {
                            final c = cards[i];
                            return _CardPill(
                              title: c.title,
                              assetLogo: c.assetLogo,
                              icon: c.icon ?? Icons.credit_card,
                              onTap: () {
                                // go to profile where user can see all cards
                                Navigator.pushNamed(context, '/profile');
                              },
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // -----------------------
                      // RECENT SERVICES
                      // See all → Services page
                      // -----------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Services',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: mycolors.textHeading,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/services');
                            },
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (recents.isEmpty)
                        _EmptyStrip(
                          icon: Icons.history_rounded,
                          message: 'Browse a service and it’ll appear here.',
                        )
                      else
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final s = recents[i];
                              return _ChipButton(
                                label: s.name,
                                onTap: () {
                                  // Optional: route to services page for now
                                  Navigator.pushNamed(context, '/services');
                                  // Later: pass s.id to open exact service page
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // -----------------------
                      // EMERGENCY (bottomsheet)
                      // -----------------------
                      Text(
                        'Emergency',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: mycolors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 10),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: _emergency.length,
                        itemBuilder: (context, i) {
                          final e = _emergency[i];
                          return _EmergencyTile(
                            name: e.name,
                            phone: e.phone,
                            url: e.url,
                            icon: e.icon ?? Icons.emergency_share_outlined,
                            asset: e.asset,
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ===== OFFICIAL KITAID NAVBAR =====
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 0, // HOME
        onTap: (index) {
          if (index == 0) return; // already on this page

          switch (index) {
            case 0: // HOME
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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

/// --------------------------
/// WIDGETS
/// --------------------------
class _RoundedSquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundedSquareButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: scheme.onPrimaryContainer),
            Text(label,
                style: text.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                )),
          ],
        ),
      ),
    );
  }
}

class _CardPill extends StatelessWidget {
  final String title;
  final String? assetLogo;
  final IconData icon;
  final VoidCallback onTap;
  const _CardPill(
      {required this.title,
      required this.onTap,
      this.assetLogo,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(mysizes.cardRadiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(mysizes.cardRadiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (assetLogo != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: scheme.onPrimaryContainer.withOpacity(0.08),
                    image: DecorationImage(
                      image: AssetImage(assetLogo!),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: scheme.onPrimaryContainer.withOpacity(0.08),
                  ),
                  child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceVariant,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final String name;
  final String phone;
  final String? url;
  final String? asset;
  final IconData icon;

  const _EmergencyTile({
    super.key,
    required this.name,
    required this.phone,
    this.url,
    required this.icon,
    this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(mysizes.cardRadiusMd),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: false,
          builder: (_) => _EmergencyBottomSheet(
            title: name,
            phone: phone,
            url: url,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(mysizes.cardRadiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (asset != null)
              Expanded(child: Image.asset(asset!, fit: BoxFit.contain))
            else
              Expanded(
                child: Icon(
                  icon,
                  size: 36,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              name,
              style: text.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStrip extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyStrip({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(mysizes.cardRadiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: text.bodyMedium)),
        ],
      ),
    );
  }
}

class _EmergencyBottomSheet extends StatelessWidget {
  final String title;
  final String phone;
  final String? url;

  const _EmergencyBottomSheet({
    super.key,
    required this.title,
    required this.phone,
    this.url,
  });

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(
            color: mycolors.Primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, -2),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: mycolors.Primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mycolors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mycolors.Primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),

            // 📞 phone tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.phone_outlined,
                size: 22,
                color: theme.iconTheme.color,
              ),
              title: Text(
                phone,
                style: textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                ),
              ),
              onTap: () => _launchPhone(phone),
            ),

            if (url != null && url!.isNotEmpty) ...[
              Divider(height: 1, color: theme.dividerColor),

              // 🌐 website tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.public_outlined,
                  size: 22,
                  color: theme.iconTheme.color,
                ),
                title: Text(
                  'Visit website',
                  style: textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  url!,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _launchUrl(url!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
