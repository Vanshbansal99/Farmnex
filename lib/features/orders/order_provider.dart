import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cart/cart_provider.dart';

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.total,
    required this.date,
    this.status = 'Pending',
  });
}

class OrderNotifier extends StateNotifier<List<Order>> {
  OrderNotifier() : super(_mockOrders);

  static final List<Order> _mockOrders = [
    Order(
      id: '5021',
      customerName: 'John Doe',
      customerEmail: 'john@example.com',
      items: [],
      total: 4299.0,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'Pending',
    ),
    Order(
      id: '5020',
      customerName: 'Jane Smith',
      customerEmail: 'jane@example.com',
      items: [],
      total: 1500.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Shipped',
    ),
  ];

  void addOrder(Order order) {
    state = [order, ...state];
  }

  void updateOrderStatus(String orderId, String newStatus) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          Order(
            id: order.id,
            customerName: order.customerName,
            customerEmail: order.customerEmail,
            items: order.items,
            total: order.total,
            date: order.date,
            status: newStatus,
          )
        else
          order
    ];
  }

  double get totalRevenue => state.fold(0, (sum, order) => sum + order.total);
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<Order>>((ref) {
  return OrderNotifier();
});
