import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'admin_drawer.dart';
import 'product_admin_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../auth/auth_provider.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(adminProductProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
          tooltip: 'Back to Analytics',
        ),
        title: Text(
          'MANAGE PRODUCTS',
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
        ],
      ),
      endDrawer: const AdminDrawer(currentPath: '/admin/products'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Inventory',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProductsTable(context, ref, products),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(BuildContext context, WidgetRef ref, List<AdminProduct> products) {
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
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Image')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Actions')),
        ],
        rows: products.map((product) => DataRow(cells: [
          DataCell(
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(product.image, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(product.category)),
          DataCell(Text('₹${product.price.toStringAsFixed(0)}')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.stock < 10 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.stock.toString(),
                style: TextStyle(
                  color: product.stock < 10 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                onPressed: () => _showEditProductDialog(context, ref, product),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _showDeleteConfirmation(context, ref, product),
              ),
            ],
          )),
        ])).toList(),
      ),
    );
  }

  static const List<String> categories = [
    'Engine',
    'Hydraulic',
    'Electrical',
    'Transmission',
    'Body & Chassis',
    'Tyres & Wheels',
    'Maintenance',
  ];

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String? selectedCategory;
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    
    XFile? pickedImage;
    Uint8List? webImage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add New Product', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      if (kIsWeb) {
                        final bytes = await image.readAsBytes();
                        setDialogState(() {
                          webImage = bytes;
                          pickedImage = image;
                        });
                      } else {
                        setDialogState(() => pickedImage = image);
                      }
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: (webImage != null || pickedImage != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb 
                                ? Image.memory(webImage!, fit: BoxFit.cover)
                                : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.darkGreen, size: 32),
                              const SizedBox(height: 8),
                              Text('Upload Product Photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: selectedCategory,
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val),
                ),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCategory == null || nameController.text.isEmpty) return;
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
                  );

                  try {
                    final token = ref.read(authProvider).token!;
                    await ref.read(adminProductProvider.notifier).createProduct(
                      name: nameController.text,
                      category: selectedCategory!,
                      price: double.tryParse(priceController.text) ?? 0.0,
                      stock: int.tryParse(stockController.text) ?? 0,
                      description: descController.text,
                      imageFile: kIsWeb ? webImage : pickedImage,
                      fileName: pickedImage?.name ?? 'product.jpg',
                      token: token,
                      isFeatured: true,
                    );
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      Navigator.pop(context); // Close add dialog
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: AppColors.white),
                child: const Text('Add Product'),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, AdminProduct product) {
    final nameController = TextEditingController(text: product.name);
    String? selectedCategory = product.category;
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final descController = TextEditingController(text: product.description);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Product', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: selectedCategory,
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setState(() => selectedCategory = val),
                ),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedCategory == null) return;
                final updatedProduct = product.copyWith(
                  name: nameController.text,
                  category: selectedCategory!,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  stock: int.tryParse(stockController.text) ?? 0,
                  description: descController.text,
                );
                ref.read(adminProductProvider.notifier).updateProduct(updatedProduct);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: AppColors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final token = ref.read(authProvider).token!;
                await ref.read(adminProductProvider.notifier).deleteProduct(product.id, token);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
