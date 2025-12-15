// lib/features/authentication/screen/homepage/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// DATA LAYERS / HOOK POINTS
class ProfileRepository extends ChangeNotifier {
  static final ProfileRepository instance = ProfileRepository._();
  ProfileRepository._();

  UserProfile? _profile;
  List<UserCard> _cards = const [];

  UserProfile? get profile => _profile;
  List<UserCard> get cards => _cards;

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
  final String? displayName;
  final String? photoUrl;
  const UserProfile({required this.uid, this.displayName, this.photoUrl});
}

class UserCard {
  final String id;
  final String title;
  final IconData? icon;
  final String? assetLogo;
  const UserCard({
    required this.id,
    required this.title,
    this.icon,
    this.assetLogo,
  });
}

class RecentServicesStore extends ChangeNotifier {
  static final RecentServicesStore instance = RecentServicesStore._();
  RecentServicesStore._();

  final List<ServiceRef> _recent = [];

  List<ServiceRef> get recent => List.unmodifiable(_recent);

  void recordBrowse(ServiceRef service) {
    _recent.removeWhere((s) => s.id == service.id);
    _recent.insert(0, service);
    if (_recent.length > 10) _recent.removeLast();
    notifyListeners();
  }

  void setRecents(List<ServiceRef> list) {
    _recent
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void clear() {
    _recent.clear();
    notifyListeners();
  }
}

class ServiceRef {
  final String id;
  final String name;
  final String? logoAsset; // ✅ logo for recent chip
  const ServiceRef(this.id, this.name, {this.logoAsset});
}

class EmergencyLink {
  final String id;
  final String name;
  final String phone;
  final String? url;
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
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cardsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _recentSub;

  // ✅ fallback mapping (if Firestore doesn't store logoAsset yet)
  static const Map<String, String> _serviceLogos = {
    'jpj': 'assets/jpj.png',
    'immigration': 'assets/immigration.png',
    'jpn': 'assets/jpn.png',
    'etiqa': 'assets/etiqa.png',
    'mysejahtera': 'assets/mysejahtera.png',
  };

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
  void initState() {
    super.initState();
    _listenAuthAndProfile();
  }

  void _listenAuthAndProfile() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _userDocSub?.cancel();
      _cardsSub?.cancel();
      _recentSub?.cancel();

      if (user == null) {
        ProfileRepository.instance.setProfile(null);
        ProfileRepository.instance.setCards(const []);
        RecentServicesStore.instance.clear();
        return;
      }

      // Users/{uid}
      _userDocSub = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        final data = doc.data();
        final name = (data?['Name'] ?? '').toString().trim();
        final photoUrl = (data?['photoUrl'] ?? '').toString().trim();

        ProfileRepository.instance.setProfile(
          UserProfile(
            uid: user.uid,
            displayName: name.isNotEmpty ? name : null,
            photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
          ),
        );
      });

      // Users/{uid}/cards
      _cardsSub = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('cards')
          .snapshots()
          .listen((snap) {
        final list = snap.docs.map((d) {
          final data = d.data();
          final title = (data['title'] ?? d.id).toString();
          return UserCard(id: d.id, title: title);
        }).toList();

        ProfileRepository.instance.setCards(list);
      });

      // ✅ Users/{uid}/recentServices
      _recentSub = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('recentServices')
          .orderBy('lastOpenedAt', descending: true)
          .limit(10)
          .snapshots()
          .listen((snap) {
        final list = snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? d.id).toString();

          // ✅ read logoAsset if you store it, fallback to local mapping
          final logo = (data['logoAsset'] ?? _serviceLogos[d.id] ?? '').toString();

          return ServiceRef(
            d.id,
            name,
            logoAsset: logo.isNotEmpty ? logo : null,
          );
        }).toList();

        RecentServicesStore.instance.setRecents(list);
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _cardsSub?.cancel();
    _recentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
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
                      // HEADER
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/profile'),
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
                            child: Text(
                              'Hi ${profile?.displayName?.trim().isNotEmpty == true ? profile!.displayName!.trim() : "there"}',
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: mycolors.Primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // MY CARDS
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
                            onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // RECENT SERVICES ✅ with logo
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
                            onPressed: () => Navigator.pushNamed(context, '/services'),
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
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final s = recents[i];
                              return _RecentChip(
                                label: s.name,
                                logoAsset: s.logoAsset,
                                onTap: () => Navigator.pushNamed(context, '/services'),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // EMERGENCY
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
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

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

/// --------------------------
/// WIDGETS
/// --------------------------
class _CardPill extends StatelessWidget {
  final String title;
  final String? assetLogo;
  final IconData icon;
  final VoidCallback onTap;
  const _CardPill({
    required this.title,
    required this.onTap,
    this.assetLogo,
    required this.icon,
  });

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

// ✅ NEW: Recent chip with small logo
class _RecentChip extends StatelessWidget {
  final String label;
  final String? logoAsset;
  final VoidCallback onTap;

  const _RecentChip({
    required this.label,
    required this.onTap,
    this.logoAsset,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: (logoAsset != null && logoAsset!.isNotEmpty)
                    ? Image.asset(
                        logoAsset!,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.public,
                          size: 14,
                          color: mycolors.Primary,
                        ),
                      )
                    : Icon(
                        Icons.public,
                        size: 14,
                        color: mycolors.Primary,
                      ),
              ),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
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
          border: Border.all(color: mycolors.Primary, width: 1.5),
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
            Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: mycolors.Primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_outlined, size: 22, color: theme.iconTheme.color),
              title: Text(phone, style: textTheme.bodyMedium?.copyWith(color: mycolors.textPrimary)),
              onTap: () => _launchPhone(phone),
            ),
            if (url != null && url!.isNotEmpty) ...[
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.public_outlined, size: 22, color: theme.iconTheme.color),
                title: Text('Visit website', style: textTheme.bodyMedium?.copyWith(color: mycolors.textPrimary)),
                subtitle: Text(url!, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _launchUrl(url!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
