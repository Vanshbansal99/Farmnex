import 'package:flutter/foundation.dart';

class ApiConstants {
  // Switch between Local and Production URLs automatically
  static const String localUrl = 'http://127.0.0.1:5000/api';
  static const String productionUrl = 'https://farmnex-api.vercel.app/api'; // REPLACE with your Vercel URL

  static String get baseUrl => kReleaseMode ? productionUrl : localUrl;
  
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
