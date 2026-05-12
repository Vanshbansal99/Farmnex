import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'admin_drawer.dart';
import '../orders/order_provider.dart';

class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
          tooltip: 'Back to Admin',
        ),
        title: Text(
          'CUSTOMER ORDERS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
            tooltip: 'Refresh Orders',
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Admin Menu',
            ),
          ),
        ],
      ),
      endDrawer: const AdminDrawer(currentPath: '/admin/orders'),
      body: orderState.when(
        data: (orders) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Management (${orders.length})',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildOrdersTable(context, ref, orders),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load orders', style: GoogleFonts.outfit(fontSize: 18)),
              TextButton(
                onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTable(BuildContext context, WidgetRef ref, List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text('No orders found.', style: GoogleFonts.outfit(color: AppColors.metallicGray)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 15,
          columns: const [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: orders.map((order) => DataRow(cells: [
            DataCell(Text('#${order.id.substring(order.id.length - 4)}', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(order.customerEmail, style: const TextStyle(fontSize: 10, color: AppColors.metallicGray)),
              ],
            )),
            DataCell(Text('₹${order.total.toStringAsFixed(0)}')),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            DataCell(
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (status) {
                  // TODO: Implement backend status update
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Processing', child: Text('Mark as Processing')),
                  const PopupMenuItem(value: 'Shipped', child: Text('Mark as Shipped')),
                  const PopupMenuItem(value: 'Delivered', child: Text('Mark as Delivered')),
                  const PopupMenuItem(value: 'Cancelled', child: Text('Mark as Cancelled')),
                ],
              ),
            ),
          ])).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered': return Colors.green;
      case 'Shipped': return Colors.blue;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }
}
