import 'package:flutter/material.dart';
import '../../navigation/navigation_service.dart';

class BottomNavBar extends StatelessWidget {
  final int? selectedIndex;
  const BottomNavBar({
    super.key,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavBarItem(icon: Icons.home, label: 'Home'),
      _NavBarItem(icon: Icons.videogame_asset, label: 'Games'),
      _NavBarItem(icon: Icons.settings, label: 'Settings'),
    ];
    
    final currentIndex = selectedIndex ?? NavigationService.getCurrentIndex(context);
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF181A20)
              : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            return GestureDetector(
              onTap: () => NavigationService.handleBottomNavigation(context, i),
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
      ),
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String label;
  const _NavBarItem({required this.icon, required this.label});
}
