import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../orders/order_provider.dart';
import 'admin_drawer.dart';
import 'product_admin_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);
    final totalRevenue = ref.watch(orderProvider.notifier).totalRevenue;
    final products = ref.watch(adminProductProvider);
    final users = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Storefront',
        ),
        title: Text(
          'ADMIN CONSOLE',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Admin Menu',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: const AdminDrawer(currentPath: '/admin'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Live Data Feed',
                  style: GoogleFonts.outfit(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatGrid(orders.length, totalRevenue, products.length, users.length),
            const SizedBox(height: 32),
            
            // Analytics Charts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRevenueChart(orders),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildCategoryDistribution(products),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Activity Feed & Orders
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Recent Orders', onAction: () {}),
                      const SizedBox(height: 16),
                      _buildRecentOrdersTable(orders),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('System Activity'),
                      const SizedBox(height: 16),
                      _buildActivityFeed(orders),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildRevenueChart(List<Order> orders) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Performance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: AppColors.metallicGray));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3000),
                      FlSpot(1, 4500),
                      FlSpot(2, 3800),
                      FlSpot(3, 6000),
                      FlSpot(4, 5200),
                      FlSpot(5, 7500),
                      FlSpot(6, 8200),
                    ],
                    isCurved: true,
                    color: AppColors.darkGreen,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.darkGreen.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<AdminProduct> products) {
    final Map<String, int> categories = {};
    for (var p in products) {
      categories[p.category] = (categories[p.category] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final colors = [AppColors.darkGreen, AppColors.accentYellow, Colors.blue, Colors.orange, Colors.purple];
    int i = 0;
    categories.forEach((cat, count) {
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        title: '$count',
        color: colors[i % colors.length],
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventory Split', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(PieChartData(sections: sections, sectionsSpace: 2)),
          ),
          const SizedBox(height: 20),
          ...categories.keys.take(3).map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[categories.keys.toList().indexOf(cat) % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(cat, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(List<Order> orders) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: orders.take(5).map((order) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.darkGreen.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart, size: 16, color: AppColors.darkGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New order from ${order.customerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(DateFormat('hh:mm a').format(order.date), style: const TextStyle(fontSize: 10, color: AppColors.metallicGray)),
                  ],
                ),
              ),
              Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        )).toList(),
      ),
    );
  }



  Widget _buildStatGrid(int totalOrders, double revenue, int totalProducts, int totalUsers) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Revenue', '₹${revenue.toStringAsFixed(0)}', Icons.payments, Colors.blue),
        _buildStatCard('Total Orders', totalOrders.toString(), Icons.shopping_cart, Colors.orange),
        _buildStatCard('Live Products', totalProducts.toString(), Icons.inventory, Colors.green),
        _buildStatCard('Customers', totalUsers.toString(), Icons.group, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.metallicGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersTable(List<Order> orders) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DataTable(
        columnSpacing: 10,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Total')),
        ],
        rows: orders.map((order) => _buildDataRow(order)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(Order order) {
    return DataRow(cells: [
      DataCell(Text(order.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
      DataCell(Text(order.customerName, style: const TextStyle(fontSize: 12))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: order.status == 'Delivered' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          order.status,
          style: TextStyle(
            fontSize: 10,
            color: order.status == 'Delivered' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      )),
      DataCell(Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
    ]);
  }
}
