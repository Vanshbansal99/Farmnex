import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';

class AdminDrawer extends ConsumerWidget {
  final String currentPath;

  const AdminDrawer({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.darkGreen, Color(0xFF081C15)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 50, color: AppColors.accentYellow),
                  const SizedBox(height: 12),
                  Text(
                    'FARMNEX ADMIN',
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.dashboard, 'Analytics', '/admin', currentPath == '/admin'),
          _buildDrawerItem(context, Icons.inventory_2_outlined, 'Manage Products', '/admin/products', currentPath == '/admin/products'),
          _buildDrawerItem(context, Icons.shopping_bag_outlined, 'Customer Orders', '/admin/orders', currentPath == '/admin/orders'),
          _buildDrawerItem(context, Icons.people_outline, 'User Management', '/admin/users', currentPath == '/admin/users'),
          _buildDrawerItem(context, Icons.view_carousel_outlined, 'Manage Catalogues', '/admin/catalogues', currentPath == '/admin/catalogues'),
          _buildDrawerItem(context, Icons.settings_outlined, 'System Settings', '/admin/settings', currentPath == '/admin/settings'),
          const Divider(),
          _buildDrawerItem(context, Icons.storefront_outlined, 'Back to Storefront', '/', false),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'Sign Out',
              style: GoogleFonts.outfit(color: AppColors.error),
            ),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String path, bool isActive) {
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.darkGreen : AppColors.metallicGray),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: isActive ? AppColors.darkGreen : AppColors.black,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        if (!isActive) {
          context.go(path);
        } else {
          Navigator.pop(context); // Just close drawer if already on page
        }
      },
      selected: isActive,
      selectedTileColor: AppColors.darkGreen.withOpacity(0.05),
    );
  }
}
