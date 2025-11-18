import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';



class KitaBottomNav extends StatelessWidget {
  const KitaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(mysizes.borderRadiusLg * 1.3),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 0,
                offset: Offset(0, 10),
                color: Color(0x1F000000), // soft shadow like mock
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Item(icon: Icons.home_rounded, index: 0, current: currentIndex, onTap: onTap),
                _Item(icon: Icons.smart_toy_rounded, index: 1, current: currentIndex, onTap: onTap),
                _Item(icon: Icons.grid_view_rounded, index: 2, current: currentIndex, onTap: onTap),
                _Item(icon: Icons.notifications_rounded, index: 3, current: currentIndex, onTap: onTap),
                _Item(icon: Icons.person_rounded, index: 4, current: currentIndex, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  bool get _isActive => index == current;

  @override
  Widget build(BuildContext context) {
    // Solid black-ish for all icons to match the screenshot
    final Color iconColor = Colors.black; // or mycolors.textPrimary if you prefer

    return InkWell(
      borderRadius: BorderRadius.circular(mysizes.borderRadiusMd),
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 6),
            // Blue underline only when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: _isActive ? 28 : 0,  // short bar like your mock
              height: 4,
              decoration: BoxDecoration(
                color: _isActive ? mycolors.Primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
