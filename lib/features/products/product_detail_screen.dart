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

    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: isLargeScreen ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? MediaQuery.of(context).size.width * 0.1 : 20.0,
            vertical: 20.0,
          ),
          child: isLargeScreen 
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildProductImage(product, isLargeScreen)),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 1, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductInfo(product),
                        const SizedBox(height: 30),
                        _buildSpecifications(product),
                        const SizedBox(height: 30),
                        _buildDescription(product.description),
                        const SizedBox(height: 40),
                        _buildBottomActionContent(context, ref, product),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product, isLargeScreen),
                  const SizedBox(height: 24),
                  _buildProductInfo(product),
                  const SizedBox(height: 30),
                  _buildSpecifications(product),
                  const SizedBox(height: 30),
                  _buildDescription(product.description),
                  const SizedBox(height: 120), // Space for bottom sheet
                ],
              ),
        ),
      ),
      bottomSheet: isLargeScreen ? null : _buildBottomAction(context, ref, product),
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

  Widget _buildProductImage(AdminProduct product, bool isLargeScreen) {
    return AspectRatio(
      aspectRatio: isLargeScreen ? 1.0 : 1.2,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Hero(
          tag: 'product_${product.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: product.image.isNotEmpty
                ? Image.network(
                    product.image,
                    fit: BoxFit.contain, // Contain looks better for part diagrams
                  )
                : const Center(
                    child: Icon(Icons.image, size: 80, color: AppColors.metallicGray),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionContent(BuildContext context, WidgetRef ref, AdminProduct product) {
    final cart = ref.watch(cartProvider);
    final isInCart = cart.any((item) => item.id == product.id);

    return Row(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(
              isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
              color: AppColors.darkGreen,
            ),
            onPressed: () {
              ref.read(cartProvider.notifier).addItem(CartItem(
                id: product.id,
                name: product.name,
                price: product.price,
                image: product.image,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.darkGreen,
                  action: SnackBarAction(
                    label: 'VIEW',
                    textColor: AppColors.accentYellow,
                    onPressed: () => context.push('/cart'),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(CartItem(
                  id: product.id,
                  name: product.name,
                  price: product.price,
                  image: product.image,
                ));
                context.push('/cart');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.darkGreen.withOpacity(0.4),
              ),
              child: Text(
                'BUY NOW',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ],
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
      child: SafeArea(
        child: _buildBottomActionContent(context, ref, product),
      ),
    );
  }
}
