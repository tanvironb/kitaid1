import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ to update recents instantly on Home
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<_Service> _all = const [
    _Service(id: 'jpj', name: 'JPJ', suggested: true, iconAsset: 'assets/jpj.png'),
    _Service(id: 'emgs', name: 'EMGS', suggested: true, iconAsset: 'assets/emgs.jpeg'),
    _Service(id: 'jpn', name: 'JPN', suggested: true, iconAsset: 'assets/jpn.png'),
    _Service(id: 'etiqa', name: 'Etiqa', suggested: false, iconAsset: 'assets/etiqa.png'),
    _Service(id: 'mysejahtera', name: 'MySejahtera', suggested: false, iconAsset: 'assets/mysejahtera.png'),
  ];

  static const Map<String, String> _serviceUrls = {
    'jpj': 'https://www.jpj.gov.my/',
    'emgs': 'https://visa.educationmalaysia.gov.my/',
    'jpn': 'https://www.jpn.gov.my/my/',
    'etiqa': 'https://www.etiqa.com.my/',
    'mysejahtera': 'https://mysejahtera.moh.gov.my/en/',
  };

  final List<String> _banners = const [
    'assets/etiqa.png',
    'assets/emgs.jpeg',
    'assets/jpj.png',
    'assets/jpn.png',
    'assets/mysejahtera.png',
  ];

  late final PageController _bannerCtrl;
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });

    _bannerCtrl = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.length <= 1) return;
      _bannerIndex = (_bannerIndex + 1) % _banners.length;
      _bannerCtrl.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  List<_Service> _filter(List<_Service> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

    // ✅ Save recent service to Firestore (persistent) + update local store (instant)
    Future<void> _recordRecentService(_Service s) async {
      // 1) Update UI instantly (Home recents updates immediately if listening)
      RecentServicesStore.instance.recordBrowse(
        ServiceRef(s.id, s.name, logoAsset: s.iconAsset),
      );

      // 2) Persist only if logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('recentServices')
          .doc(s.id)
          .set({
        'name': s.name,
        'url': _serviceUrls[s.id] ?? '',
        'logoAsset': s.iconAsset ?? '', // ✅ IMPORTANT for homepage logo chip
        'lastOpenedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }


  Future<void> _openServiceWebsite(BuildContext context, _Service s) async {
    // ✅ 1) Save to recents (persistent + instant)
    try {
      await _recordRecentService(s);
    } catch (_) {
      // don’t block website opening if saving fails
    }

    // ✅ 2) Open website
    final url = _serviceUrls[s.id];
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website not set for this service')),
      );
      return;
    }

    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter(_all);
    final suggested = filtered.where((s) => s.suggested).toList();
    final others = filtered.where((s) => !s.suggested).toList();

    return Scaffold(
      backgroundColor: mycolors.bgPrimary,
      appBar: AppBar(
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Services', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: mycolors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, color: mycolors.textPrimary),
              filled: true,
              fillColor: Colors.white,
              hintStyle: const TextStyle(color: mycolors.textPrimary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: mycolors.borderprimary, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: mycolors.Primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.white,
                child: PageView.builder(
                  controller: _bannerCtrl,
                  itemCount: _banners.length,
                  onPageChanged: (i) => _bannerIndex = i,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        _banners[i],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('Banner image not found')),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (suggested.isNotEmpty) ...[
            const Text(
              'Suggested',
              style: TextStyle(
                color: mycolors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: mysizes.fontMd,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggested.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final s = suggested[i];
                  return _ServiceChip(
                    service: s,
                    onTap: () => _openServiceWebsite(context, s),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Others',
            style: TextStyle(
              color: mycolors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: mysizes.fontMd,
            ),
          ),
          const SizedBox(height: 10),

          if (others.isEmpty && suggested.isEmpty)
            _EmptyState(
              message: _query.isEmpty
                  ? 'No services available right now.'
                  : 'No results for "$_query".',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: others.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, i) {
                final s = others[i];
                return _ServiceCard(
                  service: s,
                  onTap: () => _openServiceWebsite(context, s),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
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

class _Service {
  final String id;
  final String name;
  final bool suggested;
  final String? iconAsset;

  const _Service({
    required this.id,
    required this.name,
    required this.suggested,
    this.iconAsset,
  });
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.service, this.onTap});
  final _Service service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mycolors.btnSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: service.iconAsset != null
                    ? Image.asset(service.iconAsset!, fit: BoxFit.contain)
                    : const Icon(Icons.public, color: mycolors.Primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
               child: Text(
    service.name,
    maxLines: 1, // ✅ force single line
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: mycolors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 15, // ✅ slightly smaller text
    ),
  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, this.onTap});
  final _Service service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mycolors.borderprimary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: mycolors.btnSecondary,
                  child: service.iconAsset != null
                      ? Image.asset(
                          service.iconAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.public,
                            color: mycolors.Primary,
                            size: 36,
                          ),
                        )
                      : const Icon(Icons.public, color: mycolors.Primary, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mycolors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mycolors.borderprimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_off, color: mycolors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color.fromARGB(255, 10, 1, 1)),
            ),
          ),
        ],
      ),
    );
  }
}
