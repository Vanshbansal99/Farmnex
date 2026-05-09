import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final String? userId;
  
  // Static map to persist carts for different users in-memory during the session
  static final Map<String, List<CartItem>> _userCarts = {};

  CartNotifier(this.userId) : super(_userCarts[userId ?? 'guest'] ?? []);

  void addItem(CartItem item) {
    // Fail-safe: Block adding items if there is no logged-in user
    if (userId == null) {
      return;
    }

    final existingIndex = state.indexWhere((i) => i.id == item.id);
    List<CartItem> newState;
    if (existingIndex != -1) {
      newState = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            CartItem(
              id: state[i].id,
              name: state[i].name,
              price: state[i].price,
              image: state[i].image,
              quantity: state[i].quantity + 1,
            )
          else
            state[i]
      ];
    } else {
      newState = [...state, item];
    }
    state = newState;
    _saveCart();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveCart();
  }

  void updateQuantity(String id, int delta) {
    state = [
      for (final item in state)
        if (item.id == id)
          CartItem(
            id: item.id,
            name: item.name,
            price: item.price,
            image: item.image,
            quantity: (item.quantity + delta).clamp(1, 99),
          )
        else
          item
    ];
    _saveCart();
  }

  void _saveCart() {
    _userCarts[userId ?? 'guest'] = state;
  }

  void clear() {
    state = [];
    _userCarts[userId ?? 'guest'] = [];
  }

  double get totalAmount => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

// Industry standard: Scoped provider that provides a unique cart based on the logged-in user's email
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final authState = ref.watch(authProvider);
  // Using email as a unique identifier for mock storage
  final userEmail = authState.user?['email'];
  return CartNotifier(userEmail);
});
