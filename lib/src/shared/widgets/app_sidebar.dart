import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> menuItems;
  final int currentIndex;
  final Function(int) onItemTap;

  const AppSidebar({
    super.key,
    required this.menuItems,
    required this.currentIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo/Title
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.landscape, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Land Sales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Menu Items
          ...menuItems.asMap().entries.map((entry) {
            final item = entry.value;
            final isSelected = currentIndex == entry.key;
            return _buildMenuItem(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              isSelected: isSelected,
              onTap: () => onItemTap(entry.key),
            );
          }),
          const Spacer(),
          // Settings
          _buildMenuItem(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
