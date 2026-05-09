import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class AdminProduct {
  final String id;
  final String name;
  final String partNumber;
  final String category;
  final double price;
  final int stock;
  final String description;
  final String image;

  AdminProduct({
    required this.id,
    required this.name,
    this.partNumber = '',
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    this.image = '',
  });

  AdminProduct copyWith({
    String? name,
    String? category,
    double? price,
    int? stock,
    String? description,
    String? image,
    String? partNumber,
  }) {
    return AdminProduct(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      image: image ?? this.image,
      partNumber: partNumber ?? this.partNumber,
    );
  }

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    String imageUrl = '';
    if (images != null && images.isNotEmpty) {
      imageUrl = images[0];
      if (imageUrl.startsWith('/uploads')) {
        imageUrl = ApiConstants.baseUrl.replaceAll('/api', '') + imageUrl;
      }
    }
    
    return AdminProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      partNumber: json['partNumber'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      description: json['description'] ?? '',
      image: imageUrl,
    );
  }
}

class AdminProductNotifier extends StateNotifier<List<AdminProduct>> {
  final Dio _dio = Dio();
  
  AdminProductNotifier() : super([]) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/products');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        state = data.map((json) => AdminProduct.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void addProduct(AdminProduct product) {
    state = [product, ...state];
  }

  void updateProduct(AdminProduct updatedProduct) {
    state = [
      for (final product in state)
        if (product.id == updatedProduct.id) updatedProduct else product
    ];
  }

  void deleteProduct(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final adminProductProvider = StateNotifierProvider<AdminProductNotifier, List<AdminProduct>>((ref) {
  return AdminProductNotifier();
});
