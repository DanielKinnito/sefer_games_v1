import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(icon: Icons.home, label: 'Home'),
      _NavBarItem(icon: Icons.videogame_asset, label: 'Games'),
      _NavBarItem(icon: Icons.settings, label: 'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF181A20)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7C4DFF).withOpacity(0.18)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.12))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                items[i].icon,
                color: selected
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF7C4DFF)
                        : Theme.of(context).colorScheme.primary)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Theme.of(context).iconTheme.color?.withOpacity(0.6)),
                size: 32,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String label;
  const _NavBarItem({required this.icon, required this.label});
}
