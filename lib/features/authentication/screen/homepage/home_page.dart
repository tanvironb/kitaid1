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

  /// ✅ Card image from Firestore (download URL)
  final String? imageUrl;

  /// Optional fallbacks
  final IconData? icon;
  final String? assetLogo;

  const UserCard({
    required this.id,
    required this.title,
    this.imageUrl,
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
  final String? logoAsset;
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

  static const Map<String, String> _serviceLogos = {
    'jpj': 'assets/jpj.png',
    'emgs': 'assets/emgs.jpeg',
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

  bool _looksLikeUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;

    // ✅ Accept general http(s)
    if (s.startsWith('http://') || s.startsWith('https://')) return true;

    return false;
  }

  bool _looksLikeFirebaseStorageUrl(String? v) {
    if (v == null) return false;
    final s = v.trim();
    if (s.isEmpty) return false;
    return s.contains('firebasestorage.googleapis.com') ||
        s.contains('storage.googleapis.com');
  }

  /// ✅ SUPER ROBUST:
  /// - Case-insensitive key match (License / license / LICENSE / "license ")
  /// - Special case: IC uses "MyKad"
  /// - Special case: Driving uses "license"
  /// - Fallback: scan ALL fields for a Firebase Storage URL
  String? _pickCardImageUrl(String docId, Map<String, dynamic> data) {
    String? s(dynamic v) => v?.toString();

    final id = docId.trim().toLowerCase();

    // Build a case-insensitive map of keys
    final Map<String, dynamic> lower = {};
    for (final e in data.entries) {
      lower[e.key.toString().trim().toLowerCase()] = e.value;
    }

    // 1) IC special (your working field is "MyKad")
    if (id == 'ic' || id.contains('mykad')) {
      final v = s(lower['mykad']) ?? s(data['MyKad']);
      if (_looksLikeUrl(v)) return v!.trim();
    }

    // 2) Driving license special (field "license" but may be different case)
    if (id.contains('driving')) {
      final v = s(lower['license']) ?? s(data['license']) ?? s(data['License']);
      if (_looksLikeUrl(v)) return v!.trim();
    }

    // 3) Common keys (case-insensitive)
    const commonKeys = [
      'license',
      'mykad',
      'ic',
      'imageurl',
      'url',
      'cardimageurl',
      'front',
      'photo',
      'card',
    ];

    for (final k in commonKeys) {
      final v = s(lower[k]);
      if (_looksLikeUrl(v)) return v!.trim();
    }

    // 4) Best fallback: scan ALL values for Firebase Storage url
    for (final e in data.entries) {
      final v = s(e.value);
      if (_looksLikeFirebaseStorageUrl(v) || _looksLikeUrl(v)) {
        return v!.trim();
      }
    }

    return null;
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

      // ✅ Users/{uid}/cards
      _cardsSub = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('cards')
          .snapshots()
          .listen((snap) {
        final list = snap.docs.map((d) {
          final data = d.data();
          final title = (data['title'] ?? d.id).toString();

          final picked = _pickCardImageUrl(d.id, data);

          // ✅ DEBUG: you will see this in your VS Code debug console
          debugPrint('🪪 CARD DOC: "${d.id}" keys=${data.keys.toList()} url=$picked');

          return UserCard(
            id: d.id,
            title: title,
            imageUrl: picked,
          );
        }).toList();

        ProfileRepository.instance.setCards(list);
      });

      // Users/{uid}/recentServices
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
          final logo = _serviceLogos[d.id];
          return ServiceRef(d.id, name, logoAsset: logo);
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

  void _openCardDetails(UserCard c) {
    Navigator.pushNamed(
      context,
      '/card-detail',
      arguments: {
        'cardId': c.id,
        'title': c.title,
        'imageUrl': c.imageUrl,
      },
    );
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
                                fontWeight: FontWeight.w800,
                                color: mycolors.Primary,
                                fontSize: mysizes.fontMd,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Cards',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: mysizes.fontMd,
                              color: mycolors.textHeading,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/profile'),
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
                            childAspectRatio: 1.75,
                          ),
                          itemCount: cards.length,
                          itemBuilder: (context, i) {
                            final c = cards[i];
                            return _CardPill(
                              title: c.title,
                              imageUrl: c.imageUrl,
                              assetLogo: c.assetLogo,
                              icon: c.icon ?? Icons.credit_card,
                              onTap: () => _openCardDetails(c),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Services',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: mycolors.textHeading,
                              fontSize: mysizes.fontMd,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/services'),
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
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final s = recents[i];
                              return _ChipButton(
                                label: s.name,
                                logoAsset: s.logoAsset,
                                onTap: () =>
                                    Navigator.pushNamed(context, '/services'),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      Text(
                        'Emergency',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: mycolors.textHeading,
                          fontSize: mysizes.fontMd,
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
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

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
class _CardPill extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? assetLogo;
  final IconData icon;
  final VoidCallback onTap;

  const _CardPill({
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.assetLogo,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasUrl) {
      return Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(mysizes.cardRadiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Card image failed to load: $error');
                  return Container(
                    color: scheme.primaryContainer,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: scheme.onPrimaryContainer,
                      size: 28,
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback pill (icon)
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
  final String? logoAsset;
  final VoidCallback onTap;

  const _ChipButton({
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    logoAsset!,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
              if (logoAsset != null) const SizedBox(width: 8),
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
          Expanded
          (child: Text(message, 
          style: text.bodyMedium?.copyWith(
            fontSize: mysizes.fontSm,
            fontWeight: FontWeight.w500
          ))),
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
                    fontWeight: FontWeight.w800,
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontMd,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mycolors.Primary,
                      fontSize: mysizes.fontMd,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_outlined,
                  size: 22, color: theme.iconTheme.color),
              title: Text(phone,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: mycolors.textPrimary,
                      fontSize: mysizes.fontMd,)),
              onTap: () => _launchPhone(phone),
            ),
            if (url != null && url!.isNotEmpty) ...[
              Divider(height: 1, color: theme.dividerColor),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.public_outlined,
                    size: 22, color: theme.iconTheme.color),
                title: Text('Visit website',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: mycolors.textPrimary,
                        fontSize: mysizes.fontMd,)),
                subtitle: Text(url!,
                     style: textTheme.labelSmall?.copyWith(
                            fontSize: mysizes.fontSm,),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                onTap: () => _launchUrl(url!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
