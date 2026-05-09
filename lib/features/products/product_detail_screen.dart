import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_provider.dart';
import '../auth/auth_provider.dart';
import '../admin/product_admin_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(adminProductProvider);
    final product = allProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => AdminProduct(
        id: '0',
        name: 'Product Not Found',
        category: 'N/A',
        price: 0,
        stock: 0,
        description: 'The requested product could not be found.',
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, product.name),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product),
                  const SizedBox(height: 20),
                  _buildProductInfo(product),
                  const SizedBox(height: 30),
                  _buildSpecifications(product),
                  const SizedBox(height: 30),
                  _buildDescription(product.description),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context, ref, product),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      actions: [
        IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        IconButton(icon: const Icon(Icons.share), onPressed: () {}),
      ],
    );
  }

  Widget _buildProductImage(AdminProduct product) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Hero(
        tag: 'product_${product.id}',
        child: product.image.isNotEmpty
            ? Image.network(product.image, fit: BoxFit.cover)
            : const Icon(Icons.image, size: 100, color: AppColors.metallicGray),
      ),
    );
  }

  Widget _buildProductInfo(AdminProduct product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.category,
              style: GoogleFonts.outfit(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.accentYellow, size: 18),
                const SizedBox(width: 4),
                Text(
                  '4.5 (124 reviews)',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.metallicGray),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          product.name,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '₹${product.price.toStringAsFixed(0)}',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),
        if (product.stock < 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Only ${product.stock} left in stock!',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecifications(AdminProduct product) {
    final specs = [
      {'key': 'Category', 'value': product.category},
      {'key': 'Stock', 'value': '${product.stock} units'},
      {'key': 'Warranty', 'value': '12 Months'},
      {'key': 'Condition', 'value': 'New'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        ...specs.map((spec) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                '${spec['key']}: ',
                style: GoogleFonts.outfit(color: AppColors.metallicGray),
              ),
              Text(
                spec['value'] as String,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this item',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.outfit(
            color: AppColors.metallicGray,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref, AdminProduct product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final user = ref.read(authProvider).user;
                if (user == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text('Please login or create an account to start adding items to your cart.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Later'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/login');
                          },
                          child: const Text('Login Now'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                ref.read(cartProvider.notifier).addItem(CartItem(
                  id: product.id,
                  name: product.name,
                  price: product.price,
                  image: product.image,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to cart')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.darkGreen),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add to Cart'),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final user = ref.read(authProvider).user;
                if (user == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text('Please login to continue.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/login');
                          },
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  );
                  return;
                }
              },
              child: const Text('Buy Now'),
            ),
          ),
        ],
      ),
    );
  }
}
