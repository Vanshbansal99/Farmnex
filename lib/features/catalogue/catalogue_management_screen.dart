import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../admin/admin_drawer.dart';
import 'catalogue_provider.dart';
import '../auth/auth_provider.dart';

class CatalogueManagementScreen extends ConsumerWidget {
  const CatalogueManagementScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String catalogueId, String catalogueName) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal during delete
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Delete Catalogue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to permanently delete "$catalogueName"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDeleting ? null : () async {
                  setState(() => isDeleting = true);
                  try {
                    final token = ref.read(authProvider).token!;
                    await ref.read(catalogueProvider.notifier).deleteCatalogue(catalogueId, token);
                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catalogue deleted successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => isDeleting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delete failed: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cataloguesState = ref.watch(catalogueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
          tooltip: 'Back to Admin Dashboard',
        ),
        title: Text(
          'MANAGE CATALOGUES',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Admin Menu',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const AdminDrawer(currentPath: '/admin/catalogues'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/catalogues/build'),
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text('Create New Catalogue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: cataloguesState.when(
        data: (catalogues) {
          if (catalogues.isEmpty) {
            return Center(
              child: Text(
                'No catalogues found.\nClick the button below to create one.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: catalogues.length,
            itemBuilder: (context, index) {
              final catalogue = catalogues[index];
              final serverUrl = ApiConstants.baseUrl.replaceAll('/api', '');
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: catalogue.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '$serverUrl${catalogue.imageUrl}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 40),
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 40),
                  title: Text(
                    catalogue.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${catalogue.parts.length} Parts Defined'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, ref, catalogue.id, catalogue.name),
                        tooltip: 'Delete Catalogue',
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    context.push('/catalogue'); // Take them to user view to see it
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
