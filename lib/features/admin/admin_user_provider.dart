import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_provider.dart';

final adminUserProvider = StateNotifierProvider<AdminUserNotifier, AsyncValue<List<dynamic>>>((ref) {
  return AdminUserNotifier(ref);
});

class AdminUserNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final Ref _ref;

  AdminUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(authProvider).token;
      final response = await _ref.read(apiServiceProvider).get(
        ApiConstants.adminUsers,
        token: token,
      );
      state = AsyncValue.data(response.data as List<dynamic>);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final token = _ref.read(authProvider).token;
      await _ref.read(apiServiceProvider).delete(
        '${ApiConstants.adminUsers}/$userId',
        token: token,
      );
      // Refresh list
      await fetchUsers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
