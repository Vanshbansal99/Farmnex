import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';

final productsProvider = FutureProvider.family<List<dynamic>, Map<String, dynamic>?>((ref, query) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get(ApiConstants.products, queryParameters: query);
  return response.data;
});

final productDetailsProvider = FutureProvider.family<dynamic, String>((ref, id) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get('${ApiConstants.products}/$id');
  return response.data;
});
