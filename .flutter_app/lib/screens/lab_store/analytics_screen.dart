import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LabStoreAnalyticsScreen extends StatefulWidget {
  const LabStoreAnalyticsScreen({super.key});

  @override
  State<LabStoreAnalyticsScreen> createState() => _LabStoreAnalyticsScreenState();
}

class _LabStoreAnalyticsScreenState extends State<LabStoreAnalyticsScreen> {
  final _apiService = ApiService();
  int _refreshKey = 0;
  String _selectedPeriod = 'all'; // all, today, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Analytics'),
        backgroundColor: Colors.purple.shade700,
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
              future: _apiService.get('/api/lab-store/dashboard'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final responseData = snapshot.data;
                final data = responseData?['data'] ?? {};
                final totalTests = data['total_tests_conducted'] ?? 0;
                final totalPatients = data['total_patients_served'] ?? 0;
                final totalRevenue = (data['total_revenue'] ?? 0.0).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lab Overview',
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
                            'Total Tests Conducted',
                            totalTests.toString(),
                            Icons.science,
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

            // Test Catalog Analysis
            const Text(
              'Test Catalog Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('tests_$_refreshKey'),
              future: _apiService.get('/api/lab-store/tests'),
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
                final tests = (responseData?['data']?['tests'] ?? responseData?['tests']) as List<dynamic>? ?? [];
                
                // Calculate test metrics
                int totalTests = tests.length;
                int availableTests = tests.where((t) => t['is_available'] == true).length;
                int unavailableTests = totalTests - availableTests;
                double totalCatalogValue = tests.fold<double>(0.0, (sum, t) => 
                  sum + ((t['price'] ?? 0.0) as num).toDouble()
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInventoryCard(
                            'Total Tests',
                            totalTests.toString(),
                            Icons.medical_services,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryCard(
                            'Catalog Value',
                            '₹${totalCatalogValue.toStringAsFixed(0)}',
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
                            'Available',
                            availableTests.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInventoryCard(
                            'Unavailable',
                            unavailableTests.toString(),
                            Icons.cancel,
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

            // Test Availability Details
            const Text(
              'Test Availability Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('test_status_$_refreshKey'),
              future: _apiService.get('/api/lab-store/tests'),
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
                final tests = (responseData?['data']?['tests'] ?? responseData?['tests']) as List<dynamic>? ?? [];
                
                if (tests.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No tests to display',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                // Sort by price (descending)
                final sortedTests = List<dynamic>.from(tests);
                sortedTests.sort((a, b) => 
                  ((b['price'] ?? 0.0) as num).compareTo((a['price'] ?? 0.0) as num)
                );

                return Column(
                  children: sortedTests.take(10).map((test) {
                    return _buildTestStatusCard(test);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Order Analysis
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
              future: _apiService.get('/api/lab-store/orders'),
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
                int sampleCollectedOrders = orders.where((o) => o['status'] == 'sample_collected').length;
                int completedOrders = orders.where((o) => o['status'] == 'completed').length;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOrderMetricCard(
                            'Total Orders',
                            totalOrders.toString(),
                            Icons.assignment,
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
                            'Sample Collected',
                            sampleCollectedOrders.toString(),
                            Icons.inventory_2,
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
            const SizedBox(height: 24),

            // Category Distribution
            const Text(
              'Test Category Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              key: ValueKey('categories_$_refreshKey'),
              future: _apiService.get('/api/lab-store/tests'),
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
                final tests = (responseData?['data']?['tests'] ?? responseData?['tests']) as List<dynamic>? ?? [];
                
                // Count categories
                Map<String, int> categoryCount = {};
                for (var test in tests) {
                  String category = test['category'] ?? 'Uncategorized';
                  categoryCount[category] = (categoryCount[category] ?? 0) + 1;
                }

                if (categoryCount.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No category data available',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: categoryCount.entries.map((entry) {
                    return _buildCategoryCard(entry.key, entry.value);
                  }).toList(),
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
            colors: [Colors.purple.shade700, Colors.purple.shade500],
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

  Widget _buildTestStatusCard(Map<String, dynamic> test) {
    final isAvailable = test['is_available'] ?? false;
    
    Color statusColor = isAvailable ? Colors.green : Colors.red;
    IconData statusIcon = isAvailable ? Icons.check_circle : Icons.cancel;
    String statusText = isAvailable ? 'AVAILABLE' : 'UNAVAILABLE';

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
          test['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Category: ${test['category'] ?? 'N/A'}'),
            const SizedBox(height: 2),
            Text(
              'Price: ₹${test['price']}',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (test['delivery_time'] != null)
              Text('Delivery: ${test['delivery_time']}'),
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

  Widget _buildCategoryCard(String category, int count) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    final color = colors[category.hashCode % colors.length];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.category, color: color, size: 24),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count tests',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
