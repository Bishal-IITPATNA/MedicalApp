import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'analytics_screen.dart';
import 'order_medicines_screen.dart';
import 'my_orders_screen.dart';
import 'low_stock_medicines_screen.dart';

class MedicalStoreDashboard extends StatefulWidget {
  const MedicalStoreDashboard({super.key});

  @override
  State<MedicalStoreDashboard> createState() => _MedicalStoreDashboardState();
}

class _MedicalStoreDashboardState extends State<MedicalStoreDashboard> {
  final _authService = AuthService();
  final _apiService = ApiService();
  int _selectedIndex = 0;
  String _storeName = '';
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      if (response['success'] && mounted) {
        final profileData = response['data']['profile'];
        if (profileData != null) {
          setState(() {
            _storeName = profileData['name'] ?? 'Medical Store';
          });
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services, color: Colors.white),
            ),
          ),
          title: Text(_selectedIndex == 0 ? 'Medical Store Dashboard' : _getTitleForIndex()),
          backgroundColor: Colors.green.shade700,
          automaticallyImplyLeading: false,
          actions: [
            if (_selectedIndex == 0)
              IconButton(
                icon: const Icon(Icons.analytics),
                tooltip: 'View Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MedicalStoreAnalyticsScreen(),
                    ),
                  );
                },
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'profile') {
                  setState(() => _selectedIndex = 3);
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(),
            _buildMedicinesTab(),
            _buildOrdersTab(),
            _buildProfileTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'Medicines',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitleForIndex() {
    switch (_selectedIndex) {
      case 1:
        return 'Medicines';
      case 2:
        return 'Orders';
      case 3:
        return 'Profile';
      default:
        return 'Medical Store Dashboard';
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshKey++);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storeName.isNotEmpty ? _storeName : 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your medicines and orders efficiently',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics
          FutureBuilder(
            key: ValueKey(_refreshKey),
            future: _apiService.get('/api/medical-store/dashboard'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final response = snapshot.data;
              final data = response?['data'] as Map<String, dynamic>?;
              final totalSold = data?['total_medicines_sold'] ?? 0;
              final totalPatients = data?['total_patients_served'] ?? 0;
              final totalRevenue = data?['total_revenue'] ?? 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Medicines Sold',
                          totalSold.toString(),
                          Icons.medication,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Patients Served',
                          totalPatients.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Revenue',
                          '₹${totalRevenue.toStringAsFixed(2)}',
                          Icons.currency_rupee,
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

          // Recent Orders
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Low Stock Alert with Badge
          FutureBuilder(
            future: _apiService.get('/api/medical-store/low-stock-medicines?threshold=10'),
            builder: (context, snapshot) {
              final lowStockCount = snapshot.data?['data']?['count'] ?? snapshot.data?['count'] ?? 0;
              
              return Card(
                elevation: 2,
                color: lowStockCount > 0 ? Colors.orange.shade50 : null,
                child: ListTile(
                  leading: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                      ),
                      if (lowStockCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              lowStockCount > 9 ? '9+' : lowStockCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: const Text(
                    'Low Stock Medicines',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    lowStockCount > 0 
                        ? '$lowStockCount ${lowStockCount == 1 ? 'medicine' : 'medicines'} running low'
                        : 'All medicines are well stocked',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LowStockMedicinesScreen(),
                      ),
                    ).then((_) => setState(() => _refreshKey++));
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          // Order Medicines Button
          Card(
            elevation: 2,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shopping_bag, color: Colors.blue.shade700),
              ),
              title: const Text(
                'Order Medicines from Admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Browse and order medicines for your inventory'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderMedicinesScreen(),
                  ),
                ).then((_) => setState(() => _refreshKey++));
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // My Orders Button
          Card(
            elevation: 2,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, color: Colors.green.shade700),
              ),
              title: const Text(
                'My Orders to Admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Track your medicine orders from admin'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyOrdersScreen(),
                  ),
                ).then((_) => setState(() => _refreshKey++));
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Recent Patient Orders
          const Text(
            'Recent Patient Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          FutureBuilder(
            key: ValueKey(_refreshKey),
            future: _apiService.get('/api/medical-store/orders'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final response = snapshot.data;
              final data = response?['data'] as Map<String, dynamic>?;
              
              // Backend returns completed_orders and pending_offers
              final completedOrders = data?['completed_orders'] as List<dynamic>? ?? [];
              final pendingOffers = data?['pending_offers'] as List<dynamic>? ?? [];
              
              // Filter to show only confirmed orders
              final confirmedOrders = completedOrders.where((order) {
                final status = order['status'] as String?;
                return status == 'confirmed';
              }).toList();
              
              // Combine pending offers with confirmed orders
              final allActiveOrders = [...pendingOffers, ...confirmedOrders];
              final recentOrders = allActiveOrders.take(5).toList();

              if (recentOrders.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No orders yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: recentOrders.map((order) => _buildOrderCard(order, compact: true)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search
                  },
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () => _showAddMedicineDialog(),
                backgroundColor: Colors.green.shade700,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder(
            key: ValueKey(_refreshKey),
            future: _apiService.get('/api/medical-store/medicines'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error loading medicines', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _refreshKey++),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final responseData = snapshot.data;
              print('Medicines response: $responseData'); // Debug
              
              // Handle the API response structure - data is wrapped in 'data' key
              final medicines = (responseData?['data']?['medicines'] ?? responseData?['medicines']) as List<dynamic>? ?? [];

              if (medicines.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No medicines added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddMedicineDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medicine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return _buildMedicineCard(medicine);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final isAvailable = medicine['is_available'] ?? true;
    final stock = medicine['stock_quantity'] ?? 0;
    final isLowStock = stock < 10;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: isAvailable ? Colors.green.shade700 : Colors.grey,
          ),
        ),
        title: Text(
          medicine['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medicine['manufacturer'] != null) ...[
              const SizedBox(height: 4),
              Text('By ${medicine['manufacturer']}'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '₹${medicine['price']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stock: $stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLowStock ? Colors.red.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditMedicineDialog(medicine);
            } else if (value == 'delete') {
              _deleteMedicine(medicine['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshKey++);
      },
      child: FutureBuilder(
        key: ValueKey(_refreshKey),
        future: _apiService.get('/api/medical-store/orders'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error loading orders', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _refreshKey++),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final responseData = snapshot.data;
          final completedOrders = (responseData?['data']?['completed_orders'] ?? responseData?['completed_orders']) as List<dynamic>? ?? [];
          final pendingOffers = (responseData?['data']?['pending_offers'] ?? responseData?['pending_offers']) as List<dynamic>? ?? [];

          if (completedOrders.isEmpty && pendingOffers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending Offers Section
              if (pendingOffers.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Offers (${pendingOffers.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...pendingOffers.map((order) => _buildPendingOfferCard(order)),
                const SizedBox(height: 24),
              ],
              
              // Completed Orders Section
              if (completedOrders.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Order History (${completedOrders.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...completedOrders.map((order) => _buildOrderCard(order)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPendingOfferCard(Map<String, dynamic> order) {
    final timeoutSeconds = order['timeout_seconds'] ?? 0;
    final isExpired = order['is_expired'] ?? false;
    final minutes = (timeoutSeconds / 60).floor();
    final seconds = timeoutSeconds % 60;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isExpired ? Colors.red : Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired ? Icons.timer_off : Icons.timer,
                        size: 16,
                        color: isExpired ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpired
                            ? 'EXPIRED'
                            : '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 20, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Total: ₹${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (order['items'] != null && (order['items'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              ...((order['items'] as List).take(3).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${item['medicine_name'] ?? 'Unknown'} x${item['quantity']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))),
              if ((order['items'] as List).length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '... and ${(order['items'] as List).length - 3} more item(s)',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectOrder(order['id']),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isExpired ? null : () => _acceptOrder(order['id']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final response = await _apiService.post(
        '/api/medical-store/orders/$orderId/accept',
        {},
      );

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _refreshKey++);
      } else {
        throw Exception(response['error'] ?? 'Failed to accept order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order? It will be offered to another medical store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _apiService.post(
        '/api/medical-store/orders/$orderId/reject',
        {},
      );

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _refreshKey++);
      } else {
        throw Exception(response['error'] ?? 'Failed to reject order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {bool compact = false}) {
    final status = order['status'] ?? 'pending';
    final deliveryType = order['delivery_type'] ?? 'pickup';
    final otpVerified = order['otp_verified'] ?? false;
    final bill = order['bill'];
    
    Color statusColor;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'processing':
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'dispatched':
        statusColor = Colors.purple;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Patient ID: ${order['patient_id']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '₹${order['total_amount'] ?? 0}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  deliveryType == 'pickup' ? Icons.store : Icons.local_shipping,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  deliveryType == 'pickup' ? 'Store Pickup' : 'Home Delivery',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            
            // OTP Verification for home delivery
            if (!compact && deliveryType == 'home_delivery' && status == 'confirmed' && !otpVerified) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.security, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'OTP Verification Required',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOtpVerificationDialog(order['id']),
                      icon: const Icon(Icons.verified_user, size: 18),
                      label: const Text('Enter OTP & Dispatch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Complete Pickup button
            if (!compact && deliveryType == 'pickup' && status == 'confirmed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completePickupOrder(order['id']),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Complete Pickup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Bill Section for completed orders
            if (!compact && bill != null && status == 'completed') ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _showBillDetails(bill),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 24, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Generated',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bill['bill_number'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.green.shade700),
                    ],
                  ),
                ),
              ),
            ],
            
            if (!compact && status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrderStatus(order['id'], 'processing'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrderStatus(order['id'], 'cancelled'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBillDetails(Map<String, dynamic> bill) {
    final items = (bill['items'] as List<dynamic>?) ?? [];
    final subtotal = (bill['subtotal'] ?? 0.0).toDouble();
    final gstAmount = (bill['tax_amount'] ?? 0.0).toDouble();
    final totalAmount = (bill['total_amount'] ?? 0.0).toDouble();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('Bill Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBillRow('Bill Number', bill['bill_number'] ?? 'N/A', bold: true),
              _buildBillRow('Date', _formatBillDate(bill['bill_date'] ?? '')),
              _buildBillRow('Patient', bill['patient_name'] ?? 'N/A'),
              const Divider(height: 24),
              
              const Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['medicine_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${item['quantity']} x ₹${(item['unit_price'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(item['total_price'] ?? 0.0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),
              
              const Divider(height: 24),
              _buildBillRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              _buildBillRow('GST (${bill['tax_percentage'] ?? 5}%)', '₹${gstAmount.toStringAsFixed(2)}'),
              const Divider(height: 16),
              _buildBillRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}', bold: true, large: true),
              
              if (bill['payment_status'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bill['payment_status'] == 'paid' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        bill['payment_status'] == 'paid' ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: bill['payment_status'] == 'paid' ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment: ${bill['payment_status']?.toUpperCase() ?? 'PENDING'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: bill['payment_status'] == 'paid' ? Colors.green.shade900 : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBillDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildProfileTab() {
    return FutureBuilder(
      key: ValueKey(_refreshKey),
      future: _apiService.get('/api/medical-store/profile'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error loading profile', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _refreshKey++),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final responseData = snapshot.data;
        
        // Extract profile - API service wraps response in {success: true, data: {...}}
        final profile = responseData?['data'] ?? responseData;
        
        // Debug print to see what we're getting
        print('Response data: $responseData');
        print('Profile data: $profile');
        print('Address: ${profile?['address']}');
        print('City: ${profile?['city']}');
        print('State: ${profile?['state']}');
        print('Pincode: ${profile?['pincode']}');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.store, size: 50, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile?['name'] ?? 'Medical Store',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (profile?['phone'] != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            profile!['phone'],
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    if (profile?['license_number'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'License: ${profile!['license_number']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Store Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.green.shade700),
                    title: const Text('Address'),
                    subtitle: Text(
                      profile?['address']?.isNotEmpty == true 
                          ? profile!['address'] 
                          : 'Not set',
                      style: TextStyle(
                        color: profile?['address']?.isNotEmpty == true 
                            ? Colors.black87 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.location_city, color: Colors.green.shade700),
                    title: const Text('City'),
                    subtitle: Text(
                      profile?['city']?.isNotEmpty == true 
                          ? profile!['city'] 
                          : 'Not set',
                      style: TextStyle(
                        color: profile?['city']?.isNotEmpty == true 
                            ? Colors.black87 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.map, color: Colors.green.shade700),
                    title: const Text('State'),
                    subtitle: Text(
                      profile?['state']?.isNotEmpty == true 
                          ? profile!['state'] 
                          : 'Not set',
                      style: TextStyle(
                        color: profile?['state']?.isNotEmpty == true 
                            ? Colors.black87 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.pin_drop, color: Colors.green.shade700),
                    title: const Text('Pincode'),
                    subtitle: Text(
                      profile?['pincode']?.isNotEmpty == true 
                          ? profile!['pincode'] 
                          : 'Not set',
                      style: TextStyle(
                        color: profile?['pincode']?.isNotEmpty == true 
                            ? Colors.black87 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  if (profile?['rating'] != null && profile!['rating'] > 0) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.star, color: Colors.amber.shade700),
                      title: const Text('Rating'),
                      subtitle: Row(
                        children: [
                          Text(
                            profile['rating'].toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(profile),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final manufacturerController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    bool requiresPrescription = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name *'),
                ),
                TextField(
                  controller: manufacturerController,
                  decoration: const InputDecoration(labelText: 'Manufacturer'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price *'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                CheckboxListTile(
                  title: const Text('Requires Prescription'),
                  value: requiresPrescription,
                  onChanged: (value) {
                    setDialogState(() => requiresPrescription = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  final response = await _apiService.post('/api/medical-store/medicines', {
                    'name': nameController.text,
                    'manufacturer': manufacturerController.text,
                    'category': categoryController.text,
                    'description': descriptionController.text,
                    'price': double.parse(priceController.text),
                    'stock_quantity': int.tryParse(stockController.text) ?? 0,
                    'requires_prescription': requiresPrescription,
                  });

                  if (!mounted) return;
                  Navigator.pop(context); // Close loading
                  
                  if (response['success'] == true) {
                    Navigator.pop(context); // Close dialog
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medicine added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['error'] ?? 'Failed to add medicine'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(Map<String, dynamic> medicine) {
    final nameController = TextEditingController(text: medicine['name']);
    final priceController = TextEditingController(text: medicine['price'].toString());
    final stockController = TextEditingController(text: medicine['stock_quantity'].toString());
    bool isAvailable = medicine['is_available'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Medicine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                title: const Text('Available'),
                value: isAvailable,
                onChanged: (value) {
                  setDialogState(() => isAvailable = value ?? true);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.put('/api/medical-store/medicines/${medicine['id']}', {
                    'name': nameController.text,
                    'price': double.parse(priceController.text),
                    'stock_quantity': int.parse(stockController.text),
                    'is_available': isAvailable,
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMedicine(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/api/medical-store/medicines/$id');
        setState(() => _refreshKey++);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showOtpVerificationDialog(int orderId) async {
    final otpController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Verify OTP'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the 6-digit OTP provided by the patient:'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Verify & Dispatch'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final otp = otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await _apiService.post(
        '/api/medical-store/orders/$orderId/verify-otp',
        {'otp': otp},
      );

      if (response['success'] && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        final message = data?['message'] ?? 'OTP verified! Order dispatched successfully.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _refreshKey++);
      } else {
        throw Exception(response['error'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completePickupOrder(int orderId) async {
    final otpController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Text('Complete Pickup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the 6-digit OTP provided by the patient:'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Verify & Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final otp = otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await _apiService.post(
        '/api/medical-store/orders/$orderId/verify-otp',
        {'otp': otp},
      );

      if (response['success'] && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        final message = data?['message'] ?? 'Order completed successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _refreshKey++);
      } else {
        throw Exception(response['error'] ?? 'Failed to complete order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      await _apiService.put('/api/medical-store/orders/$orderId', {
        'status': status,
      });

      setState(() => _refreshKey++);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${status == 'processing' ? 'accepted' : 'declined'} successfully'),
            backgroundColor: status == 'processing' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog(Map<String, dynamic>? profile) {
    final nameController = TextEditingController(text: profile?['name'] ?? '');
    final phoneController = TextEditingController(text: profile?['phone'] ?? '');
    final licenseController = TextEditingController(text: profile?['license_number'] ?? '');
    final addressController = TextEditingController(text: profile?['address'] ?? '');
    final cityController = TextEditingController(text: profile?['city'] ?? '');
    final stateController = TextEditingController(text: profile?['state'] ?? '');
    final pincodeController = TextEditingController(text: profile?['pincode'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Store name is required')),
                );
                return;
              }

              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                await _apiService.put('/api/medical-store/profile', {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'license_number': licenseController.text,
                  'address': addressController.text,
                  'city': cityController.text,
                  'state': stateController.text,
                  'pincode': pincodeController.text,
                });

                if (!mounted) return;
                Navigator.pop(context); // Close loading
                Navigator.pop(context); // Close dialog
                
                setState(() => _refreshKey++);
                await _loadStoreData(); // Reload store name
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
