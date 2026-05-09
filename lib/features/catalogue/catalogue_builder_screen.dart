import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import 'catalogue_part_model.dart';
import 'catalogue_provider.dart';
import '../admin/product_admin_provider.dart';
import '../auth/auth_provider.dart';

class CatalogueBuilderScreen extends ConsumerStatefulWidget {
  const CatalogueBuilderScreen({super.key});

  @override
  ConsumerState<CatalogueBuilderScreen> createState() => _CatalogueBuilderScreenState();
}

class _CatalogueBuilderScreenState extends ConsumerState<CatalogueBuilderScreen> {
  final _nameController = TextEditingController();
  XFile? _imageFile;
  Uint8List? _imageBytes; // For web display
  final List<CataloguePart> _parts = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
        _parts.clear(); // reset parts if new image is loaded
      });
    }
  }

  void _handleTapOnImage(BuildContext context, TapUpDetails details) {
    if (_imageFile == null) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    final xFraction = details.localPosition.dx / size.width;
    final yFraction = details.localPosition.dy / size.height;

    _showPartDetailsDialog(xFraction, yFraction);
  }

  Future<void> _showPartDetailsDialog(double xFraction, double yFraction) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Engine'; // Default category

    final List<String> categories = ['Engine', 'Transmission', 'Hydraulic', 'Filters', 'Electrical', 'Body', 'Wheels'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Part Hotspot', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Part Name', icon: Icon(Icons.title)),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', icon: Icon(Icons.category)),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedCategory = val;
                  },
                ),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Part Number', icon: Icon(Icons.tag)),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (₹)', icon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', icon: Icon(Icons.description)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
              child: const Text('Save Part'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _parts.add(CataloguePart(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text,
          partNumber: numberController.text,
          price: double.tryParse(priceController.text) ?? 0,
          description: descController.text,
          category: selectedCategory,
          xFraction: xFraction,
          yFraction: yFraction,
        ));
      });
    }
  }

  Future<void> _saveCatalogue() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalogue Name is required (Left Sidebar).')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a catalogue image.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authProvider).token!;
      await ref.read(catalogueProvider.notifier).createCatalogue(
        name: _nameController.text,
        imageFile: kIsWeb ? _imageBytes : _imageFile,
        fileName: _imageFile!.name,
        parts: _parts,
        token: token,
      );
      
      if (mounted) {
        // Refresh products to sync with newly added parts
        await ref.read(adminProductProvider.notifier).fetchProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalogue created successfully!'), backgroundColor: AppColors.darkGreen));
        context.pop(); // Go back to management screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BUILD CATALOGUE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_imageFile != null)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveCatalogue,
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
              label: const Text('Publish', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar (Controls)
          Container(
            width: 300,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Catalogue Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_imageFile == null ? 'Upload Image' : 'Change Image'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Mapped Parts (${_parts.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _parts.length,
                    itemBuilder: (context, index) {
                      final p = _parts[index];
                      return ListTile(
                        dense: true,
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(p.partNumber),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () {
                            setState(() => _parts.removeAt(index));
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Right Area (Interactive Builder)
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: _imageFile == null
                  ? Center(child: Text('Upload an image to start mapping.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)))
                  : InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return AspectRatio(
                              // In a real app we'd decode the image to get exact aspect ratio,
                              // for MVP builder we assume a standard fit layout and map relative constraints.
                              aspectRatio: 4 / 3, // MVP fixed aspect ratio
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Base Image
                                  Builder(
                                    builder: (context) {
                                      return GestureDetector(
                                        onTapUp: (details) => _handleTapOnImage(context, details),
                                        child: kIsWeb 
                                          ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                                          : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
                                      );
                                    }
                                  ),
                                  
                                  // Render mapped hotspots
                                  ..._parts.map((part) {
                                    return Align(
                                      alignment: FractionalOffset(part.xFraction, part.yFraction),
                                      child: FractionalTranslation(
                                        translation: const Offset(-0.5, -0.5),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentYellow,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Center(child: Icon(Icons.add, size: 16)),
                                        ),
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
        ],
      ),
    );
  }
}
