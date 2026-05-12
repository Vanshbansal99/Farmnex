import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final List<dynamic> items;
  final double total;
  final DateTime date;
  final String status;
  final bool isDelivered;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.total,
    required this.date,
    this.status = 'Pending',
    this.isDelivered = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      customerName: json['user']?['name'] ?? 'Guest',
      customerEmail: json['user']?['email'] ?? 'N/A',
      items: json['orderItems'] ?? [],
      total: (json['totalPrice'] as num).toDouble(),
      date: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'Processing',
      isDelivered: json['isDelivered'] ?? false,
    );
  }
}

class OrderNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(authProvider).token;
      final response = await _ref.read(apiServiceProvider).get(
        ApiConstants.orders,
        token: token,
      );
      final List<dynamic> data = response.data;
      state = AsyncValue.data(data.map((o) => Order.fromJson(o)).toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final token = _ref.read(authProvider).token;
      await _ref.read(apiServiceProvider).post(
        ApiConstants.orders,
        data: orderData,
        token: token,
      );
      // Refresh list
      await fetchOrders();
      return true;
    } catch (e) {
      return false;
    }
  }

  double get totalRevenue {
    return state.when(
      data: (orders) => orders.fold(0.0, (sum, order) => sum + order.total),
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderNotifier(ref);
});
