import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'cart_provider.dart';
import '../orders/order_provider.dart';
import '../auth/auth_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(context, ref, item);
                    },
                  ),
                ),
                _buildCheckoutSection(context, ref, cartItems, total),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 100, color: AppColors.lightGray),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(fontSize: 18, color: AppColors.metallicGray),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.settings_suggest_outlined, size: 40, color: AppColors.darkGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(color: AppColors.darkGreen, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQtyBtn(Icons.remove, () {
                      ref.read(cartProvider.notifier).updateQuantity(item.id, -1);
                    }),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQtyBtn(Icons.add, () {
                      ref.read(cartProvider.notifier).updateQuantity(item.id, 1);
                    }),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeItem(item.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.black),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, WidgetRef ref, List<CartItem> items, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Total',
                  style: GoogleFonts.outfit(fontSize: 16, color: AppColors.metallicGray),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final user = ref.read(authProvider).user;
                  if (user == null) {
                    context.push('/login');
                    return;
                  }

                  // Create Order
                  final newOrder = Order(
                    id: '#ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    customerName: user['name'] ?? 'Unknown',
                    customerEmail: user['email'] ?? 'Unknown',
                    items: List.from(items),
                    total: total,
                    date: DateTime.now(),
                  );

                  ref.read(orderProvider.notifier).addOrder(newOrder);
                  ref.read(cartProvider.notifier).clear();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Order Successful!',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your parts are being prepared for dispatch.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppColors.metallicGray),
                          ),
                        ],
                      ),
                      actions: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/');
                            },
                            child: const Text('BACK TO HOME'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('PLACE ORDER NOW'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
