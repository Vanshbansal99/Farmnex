import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_provider.dart';
import '../auth/auth_provider.dart';
import 'catalogue_part_model.dart';

/// A dialog that pops up when a user taps on a part hotspot.
/// Shows part details and an Add to Cart button.
class PartPopupDialog extends ConsumerWidget {
  final CataloguePart part;

  const PartPopupDialog({super.key, required this.part});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Part icon header ──
            Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.darkGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.settings_suggest_rounded,
                  size: 60,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Part name ──
            Text(
              part.name,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),

            // ── Part number badge ──
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Part #${part.partNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Description ──
            Text(
              part.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            // ── Price row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '₹${part.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Buttons row ──
            Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Close',
                        style: GoogleFonts.outfit(color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                // Add to Cart
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final user = ref.read(authProvider).user;
                      Navigator.pop(context);
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to add items to cart'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      ref.read(cartProvider.notifier).addItem(
                        CartItem(
                          id: part.id,
                          name: part.name,
                          price: part.price,
                          image: '', // Hotspots don't have individual images
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${part.name} added to cart!'),
                          backgroundColor: AppColors.darkGreen,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: Text('Add to Cart',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
