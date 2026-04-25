import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MedicalStoreAnalyticsScreen extends StatefulWidget {
  const MedicalStoreAnalyticsScreen({super.key});

  @override
  State<MedicalStoreAnalyticsScreen> createState() => _MedicalStoreAnalyticsScreenState();
}

class _MedicalStoreAnalyticsScreenState extends State<MedicalStoreAnalyticsScreen> {
  final _apiService = ApiService();
  int _refreshKey = 0;
  String _selectedPeriod = 'all'; // all, today, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshKey++),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _refreshKey++);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period Selector
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Period',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'today', label: Text('Today')),
                        ButtonSegment(value: 'week', label: Text('Week')),
                        ButtonSegment(value: 'month', label: Text('Month')),
                        ButtonSegment(value: 'all', label: Text('All Time')),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() => _selectedPeriod = selected.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Overview Statistics
            FutureBuilder(
              key: ValueKey('dashboard_$_refreshKey'),
              future: _apiService.get('/api/medical-store/dashboard'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final data = snapshot.data?['data'] ?? snapshot.data ?? {};
                final totalSold = data['total_medicines_sold'] ?? 0;
                final totalPatients = data['total_patients_served'] ?? 0;
                final totalRevenue = (data['total_revenue'] ?? 0.0).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Medicines Sold',
                            totalSold.toString(),
                            Icons.local_pharmacy,
                            Colors.blue.shade600,
                            Colors.blue.shade50,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Patients Served',
                            totalPatients.toString(),
                            Icons.people,
                            Colors.orange.shade600,
                            Colors.orange.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRevenueCard(totalRevenue),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Top Selling Medicines
            const Text(
              'Inventory Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('medicines_$_refreshKey'),
              future: _apiService.get('/api/medical-store/medicines'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final responseData = snapshot.data;
                final medicines = (responseData?['data']?['medicines'] ?? responseData?['medicines']) as List<dynamic>? ?? [];
                
                // Calculate inventory metrics
                int totalMedicines = medicines.length;
                int lowStockCount = medicines.where((m) => (m['stock_quantity'] ?? 0) < 10).length;
                int outOfStockCount = medicines.where((m) => (m['stock_quantity'] ?? 0) == 0).length;
                double totalInventoryValue = medicines.fold<double>(0.0, (sum, m) => 
                  sum + ((m['stock_quantity'] ?? 0) * (m['price'] ?? 0.0))
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInventoryCard(
                            'Total Medicines',
                            totalMedicines.toString(),
                            Icons.inventory,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryCard(
                            'Inventory Value',
                            '₹${totalInventoryValue.toStringAsFixed(2)}',
                            Icons.account_balance_wallet,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInventoryCard(
                            'Low Stock',
                            lowStockCount.toString(),
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryCard(
                            'Out of Stock',
                            outOfStockCount.toString(),
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Medicine Stock Details
            const Text(
              'Stock Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('stock_$_refreshKey'),
              future: _apiService.get('/api/medical-store/medicines'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final responseData = snapshot.data;
                final medicines = (responseData?['data']?['medicines'] ?? responseData?['medicines']) as List<dynamic>? ?? [];
                
                if (medicines.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No medicines to display',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                // Sort by stock quantity (ascending)
                final sortedMedicines = List<dynamic>.from(medicines);
                sortedMedicines.sort((a, b) => 
                  (a['stock_quantity'] ?? 0).compareTo(b['stock_quantity'] ?? 0)
                );

                return Column(
                  children: sortedMedicines.take(10).map((medicine) {
                    return _buildStockStatusCard(medicine);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Orders Analysis
            const Text(
              'Order Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('orders_$_refreshKey'),
              future: _apiService.get('/api/medical-store/orders'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final responseData = snapshot.data;
                final orders = (responseData?['data']?['orders'] ?? responseData?['orders']) as List<dynamic>? ?? [];
                
                // Calculate order metrics
                int totalOrders = orders.length;
                int pendingOrders = orders.where((o) => o['status'] == 'pending').length;
                int processingOrders = orders.where((o) => o['status'] == 'processing').length;
                int completedOrders = orders.where((o) => o['status'] == 'completed').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOrderMetricCard(
                            'Total Orders',
                            totalOrders.toString(),
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOrderMetricCard(
                            'Pending',
                            pendingOrders.toString(),
                            Icons.hourglass_empty,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOrderMetricCard(
                            'Processing',
                            processingOrders.toString(),
                            Icons.sync,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOrderMetricCard(
                            'Completed',
                            completedOrders.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [bgColor, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.currency_rupee, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Revenue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${revenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusCard(Map<String, dynamic> medicine) {
    final stock = medicine['stock_quantity'] ?? 0;
    final isLowStock = stock < 10;
    final isOutOfStock = stock == 0;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isOutOfStock) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'OUT OF STOCK';
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'LOW STOCK';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'IN STOCK';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          medicine['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Stock: $stock units'),
            const SizedBox(height: 2),
            Text(
              'Price: ₹${medicine['price']}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 10,
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
