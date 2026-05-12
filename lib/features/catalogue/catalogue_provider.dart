import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'catalogue_part_model.dart';
import '../../core/constants/api_constants.dart';

final catalogueProvider = StateNotifierProvider<CatalogueNotifier, AsyncValue<List<Catalogue>>>((ref) {
  return CatalogueNotifier();
});

class CatalogueNotifier extends StateNotifier<AsyncValue<List<Catalogue>>> {
  final Dio _dio = Dio();

  CatalogueNotifier() : super(const AsyncValue.loading()) {
    fetchCatalogues();
  }

  Future<void> fetchCatalogues({bool isSilent = false}) async {
    try {
      if (!isSilent) state = const AsyncValue.loading();
      final response = await _dio.get('${ApiConstants.baseUrl}/catalogues');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final catalogues = data.map((json) => Catalogue.fromJson(json)).toList();
        state = AsyncValue.data(catalogues);
      } else {
        if (!isSilent) state = AsyncValue.error('Failed to load catalogues', StackTrace.current);
      }
    } catch (e, st) {
      if (!isSilent) state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCatalogue({
    required String name,
    required dynamic imageFile, // Can be File or XFile or bytes depending on platform
    required String fileName,
    required List<CataloguePart> parts,
    required String token,
  }) async {
    try {
      MultipartFile multipartFile;
      
      // Determine content type based on extension (simple fallback to jpeg if none)
      String ext = fileName.split('.').last.toLowerCase();
      if (ext != 'png' && ext != 'jpg' && ext != 'jpeg' && ext != 'webp') ext = 'jpeg';
      final mediaType = MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
      
      // Handle web bytes vs native file path
      if (imageFile is List<int>) {
        multipartFile = MultipartFile.fromBytes(imageFile, filename: fileName, contentType: mediaType);
      } else {
        multipartFile = await MultipartFile.fromFile(imageFile.path, filename: fileName, contentType: mediaType);
      }

      FormData formData = FormData.fromMap({
        'name': name,
        'image': multipartFile,
        'parts': jsonEncode(parts.map((p) => p.toJson()).toList()),
      });

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/catalogues',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        // Refresh the list after successful creation
        await fetchCatalogues();
      } else {
        throw Exception('Failed to create catalogue');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }
  Future<void> deleteCatalogue(String id, String token) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/catalogues/$id',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        // Silent refresh to prevent full-screen loading spinner
        await fetchCatalogues(isSilent: true);
      } else {
        throw Exception('Failed to delete catalogue');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? e.message;
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }
}
