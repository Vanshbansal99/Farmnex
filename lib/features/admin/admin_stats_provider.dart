import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_provider.dart';

final adminStatsProvider = StateNotifierProvider<AdminStatsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return AdminStatsNotifier(ref);
});

class AdminStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;

  AdminStatsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(authProvider).token;
      final response = await _ref.read(apiServiceProvider).get(
        ApiConstants.adminStats,
        token: token,
      );
      state = AsyncValue.data(response.data as Map<String, dynamic>);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
