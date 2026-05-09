import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/product_admin_provider.dart';

class ProductSearchDelegate extends SearchDelegate {
  final List<AdminProduct> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where((p) => 
      p.name.toLowerCase().contains(query.toLowerCase()) || 
      p.partNumber.toLowerCase().contains(query.toLowerCase()) ||
      p.category.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          title: Text(product.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          subtitle: Text('${product.category} • PN: ${product.partNumber}'),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.image.isNotEmpty 
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product.image, fit: BoxFit.cover))
              : const Icon(Icons.settings, color: AppColors.darkGreen),
          ),
          onTap: () {
            context.push('/product/${product.id}');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products.where((p) => 
      p.name.toLowerCase().contains(query.toLowerCase()) || 
      p.partNumber.toLowerCase().contains(query.toLowerCase()) ||
      p.category.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        final name = product.name;
        final indexInQuery = name.toLowerCase().indexOf(query.toLowerCase());
        
        return ListTile(
          title: RichText(
            text: TextSpan(
              text: name.substring(0, indexInQuery),
              style: GoogleFonts.outfit(color: Colors.grey),
              children: [
                TextSpan(
                  text: name.substring(indexInQuery, indexInQuery + query.length),
                  style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: name.substring(indexInQuery + query.length),
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ],
            ),
          ),
          subtitle: Text(product.category, style: const TextStyle(fontSize: 10)),
          onTap: () {
            query = name;
            showResults(context);
          },
        );
      },
    );
  }
}
