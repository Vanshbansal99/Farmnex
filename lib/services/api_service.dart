import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<Response> post(String path, {dynamic data, String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      return await _dio.post(path, data: data, options: options);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> get(String path, {String? token, Map<String, dynamic>? queryParameters}) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      return await _dio.get(path, options: options, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {String? token}) async {
    try {
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      return await _dio.delete(path, options: options);
    } catch (e) {
      rethrow;
    }
  }
}
