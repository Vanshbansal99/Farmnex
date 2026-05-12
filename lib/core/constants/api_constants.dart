class ApiConstants {
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  
  // Products
  static const String products = '/products';
  
  // Orders
  static const String orders = '/orders';
  static const String myOrders = '/orders/myorders';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminRevenue = '/admin/revenue';
  static const String adminCatalogues = '/admin/catalogues';
}
