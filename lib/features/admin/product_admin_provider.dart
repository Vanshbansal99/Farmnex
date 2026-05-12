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
  final bool isFeatured;

  AdminProduct({
    required this.id,
    required this.name,
    this.partNumber = '',
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    this.image = '',
    this.isFeatured = false,
  });

  AdminProduct copyWith({
    String? name,
    String? category,
    double? price,
    int? stock,
    String? description,
    String? image,
    String? partNumber,
    bool? isFeatured,
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
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    String imageUrl = '';
    if (images != null && images.isNotEmpty) {
      imageUrl = images[0];
      if (imageUrl.startsWith('/uploads')) {
        imageUrl = ApiConstants.baseUrl.replaceAll('/api', '') + imageUrl;
      } else if (!imageUrl.startsWith('http')) {
        // Fallback for any other relative paths
        imageUrl = ApiConstants.baseUrl.replaceAll('/api', '') + '/' + imageUrl;
      }
    }
    
    return AdminProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      partNumber: json['partNumber'] ?? '',
      category: json['category'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      description: json['description'] ?? '',
      image: imageUrl,
      isFeatured: json['isFeatured'] == true || json['isFeatured'].toString() == 'true',
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

  Future<void> createProduct({
    required String name,
    required String category,
    required double price,
    required int stock,
    required String description,
    required dynamic imageFile, // File, XFile, or bytes
    required String fileName,
    required String token,
    bool isFeatured = false,
  }) async {
    try {
      MultipartFile? multipartFile;
      if (imageFile != null) {
        if (imageFile is List<int>) {
          multipartFile = MultipartFile.fromBytes(imageFile, filename: fileName);
        } else {
          multipartFile = await MultipartFile.fromFile(imageFile.path, filename: fileName);
        }
      }

      final formData = FormData.fromMap({
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': description,
        'isFeatured': isFeatured,
        if (multipartFile != null) 'image': multipartFile,
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/products',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        final newProduct = AdminProduct.fromJson(response.data);
        state = [newProduct, ...state];
      }
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
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

  Future<void> deleteProduct(String id, String token) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/products/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        state = state.where((p) => p.id != id).toList();
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}

final adminProductProvider = StateNotifierProvider<AdminProductNotifier, List<AdminProduct>>((ref) {
  return AdminProductNotifier();
});
