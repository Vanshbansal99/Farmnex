import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'admin_drawer.dart';
import '../auth/auth_provider.dart';
import 'admin_user_provider.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(adminUserProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
          tooltip: 'Back to Admin',
        ),
        title: Text(
          'USER MANAGEMENT',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminUserProvider.notifier).fetchUsers(),
            tooltip: 'Refresh List',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Admin Menu',
            ),
          ),
        ],
      ),
      endDrawer: const AdminDrawer(currentPath: '/admin/users'),
      body: userState.when(
        data: (users) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Users (${users.length})',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildUsersTable(context, ref, users),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load users', style: GoogleFonts.outfit(fontSize: 18)),
              TextButton(
                onPressed: () => ref.read(adminUserProvider.notifier).fetchUsers(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTable(BuildContext context, WidgetRef ref, List<dynamic> users) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('No users found.', style: GoogleFonts.outfit(color: AppColors.metallicGray)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) => DataRow(cells: [
            DataCell(Text(user['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(user['email'] ?? 'N/A')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user['role'] == 'admin' ? AppColors.darkGreen.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (user['role'] as String? ?? 'user').toUpperCase(),
                  style: TextStyle(
                    color: user['role'] == 'admin' ? AppColors.darkGreen : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: user['role'] == 'admin' ? null : () => _confirmDelete(context, ref, user),
              ),
            ),
          ])).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to remove ${user['name']}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await ref.read(adminUserProvider.notifier).deleteUser(user['_id']);
              
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('User removed successfully'), 
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
