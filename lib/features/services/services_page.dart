import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Example service data — you’ll replace icons/images later
  final List<_Service> _all = const [
    _Service(id: 'jpj', name: 'JPJ', suggested: true),
    _Service(id: 'immigration', name: 'Immigration', suggested: true),
    _Service(id: 'jpn', name: 'JPN', suggested: true),
    _Service(id: 'etiqa', name: 'Etiqa', suggested: false),
    _Service(id: 'mysejahtera', name: 'MySejahtera', suggested: false),
  ];

  // ✅ Website mapping (tap service -> open url)
  static const Map<String, String> _serviceUrls = {
    'jpj': 'https://www.jpj.gov.my/',
    'immigration': 'https://www.imi.gov.my/',
    'jpn': 'https://www.jpn.gov.my/my/',
    'etiqa': 'https://www.etiqa.com.my/',
    'mysejahtera': 'https://mysejahtera.moh.gov.my/en/',
  };

  Future<void> _openServiceWebsite(BuildContext context, _Service s) async {
    final url = _serviceUrls[s.id];
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website not set for this service')),
      );
      return;
    }

    final uri = Uri.parse(url);

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // opens browser directly
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the website')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filters by search term
  List<_Service> _filter(List<_Service> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter(_all);
    final suggested = filtered.where((s) => s.suggested).toList();
    final others = filtered.where((s) => !s.suggested).toList();

    return Scaffold(
      backgroundColor: mycolors.bgPrimary,

      // ===== APP BAR (same style as Settings header) =====
      appBar: AppBar(
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 🔍 Search field
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: mycolors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, color: mycolors.textPrimary),
              filled: true,
              fillColor: Colors.white,
              hintStyle: const TextStyle(color: mycolors.textPrimary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                    color: mycolors.borderprimary, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: mycolors.Primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🖼️ Placeholder box for slideshow / banner images
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: mycolors.borderprimary.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'Slideshow / Promo Area\n(You can add images later)',
                textAlign: TextAlign.center,
                style: TextStyle(color: mycolors.textPrimary),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🏷️ Suggested services
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

          // 📦 Others section
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
                childAspectRatio: 1.3,
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

      // ===== OFFICIAL KITAID NAVBAR =====
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

// ============= Helper Classes =============

class _Service {
  final String id;
  final String name;
  final bool suggested;
  const _Service({
    required this.id,
    required this.name,
    required this.suggested,
  });
}

// Horizontal chips for "Suggested"
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
            const CircleAvatar(
              radius: 22,
              backgroundColor: mycolors.Primary,
              child: Icon(Icons.public, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mycolors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid cards for "Others"
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
          border:
              Border.all(color: mycolors.borderprimary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: mycolors.Primary,
              child: Icon(Icons.public, color: Colors.white),
            ),
            const Spacer(),
            Text(
              service.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: mycolors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shown when no results match
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
        border:
            Border.all(color: mycolors.borderprimary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_off, color: mycolors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: mycolors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
