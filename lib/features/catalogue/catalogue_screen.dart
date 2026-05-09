import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import 'catalogue_part_model.dart';
import 'part_hotspot_widget.dart';
import 'catalogue_provider.dart';

/// Interactive catalogue screen where users can explore parts visually.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cataloguesState = ref.watch(catalogueProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'SPARE PARTS CATALOGUE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: cataloguesState.when(
        data: (catalogues) {
          if (catalogues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No catalogues available.\nPlease check back later.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Ensure index is valid
          if (_selectedIndex >= catalogues.length) _selectedIndex = 0;
          final currentCatalogue = catalogues[_selectedIndex];
          final serverUrl = ApiConstants.baseUrl.replaceAll('/api', '');

          return Column(
            children: [
              // ── Catalogue Selector Header ──
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkGreen,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: catalogues.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentYellow : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? AppColors.accentYellow : Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              catalogues[index].name.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.darkGreen : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Main Content Area ──
              Expanded(
                child: Container(
                  color: Colors.grey.shade50,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // ── The Base Image ──
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '$serverUrl${currentCatalogue.imageUrl}',
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.blueGrey.shade50,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey.shade400),
                                              const SizedBox(height: 10),
                                              Text('Catalogue image not found', style: GoogleFonts.outfit(color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                
                                // ── The Hotspots ──
                                ...currentCatalogue.parts.map((part) {
                                  return Align(
                                    alignment: FractionalOffset(part.xFraction, part.yFraction),
                                    child: FractionalTranslation(
                                      translation: const Offset(-0.5, -0.5),
                                      child: PartHotspotWidget(part: part),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // ── Bottom Info Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.darkGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap on the glowing hotspots to view part details and add them to your cart.',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
