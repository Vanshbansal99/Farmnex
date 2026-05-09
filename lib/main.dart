import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/products/product_detail_screen.dart';
import 'features/products/category_products_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/orders/my_orders_screen.dart';
import 'features/admin/manage_products_screen.dart';
import 'features/admin/customer_orders_screen.dart';
import 'features/admin/user_management_screen.dart';
import 'features/admin/system_settings_screen.dart';
import 'features/catalogue/catalogue_screen.dart';
import 'features/catalogue/catalogue_management_screen.dart';
import 'features/catalogue/catalogue_builder_screen.dart';

void main() {
  runApp(const ProviderScope(child: FarmNexApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.token != null;
      final isAdmin = authState.user?['role'] == 'admin';
      final isGoingToAdmin = state.matchedLocation.startsWith('/admin');
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignup = state.matchedLocation == '/signup';

      if (isGoingToAdmin && !isAdmin) {
        return '/login';
      }

      if (isLoggedIn && (isGoingToLogin || isGoingToSignup)) {
        return isAdmin ? '/admin' : '/profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/category/:name',
        builder: (context, state) => CategoryProductsScreen(categoryName: state.pathParameters['name']!),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) => const CatalogueScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const ManageProductsScreen(),
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const CustomerOrdersScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SystemSettingsScreen(),
          ),
          GoRoute(
            path: 'catalogues',
            builder: (context, state) => const CatalogueManagementScreen(),
            routes: [
              GoRoute(
                path: 'build',
                builder: (context, state) => const CatalogueBuilderScreen(),
              ),
            ]
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
    ],
  );
});

class FarmNexApp extends ConsumerWidget {
  const FarmNexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FarmNex',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
