import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  // In a real app, you'd get the token from authProvider
  final response = await apiService.get('/admin/stats');
  return response.data;
});

final revenueAnalyticsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.get('/admin/revenue');
  return response.data;
});
