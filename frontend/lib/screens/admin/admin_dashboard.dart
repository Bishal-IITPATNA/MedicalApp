import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'admin_profile_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_home_delivery_orders_screen.dart';
import 'admin_store_orders_screen.dart';
import 'admin_medicine_catalog_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _homeDeliveryOrders = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _storeOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final dashboardResponse = await _apiService.get('/api/admin/dashboard');
      final ordersResponse = await _apiService.get('/api/admin/home-delivery-orders');
      final usersResponse = await _apiService.get('/api/admin/users');
      final storeOrdersResponse = await _apiService.get('/api/admin/store-orders?status=pending');
      
      // Debug: Print the raw responses
      print('Dashboard Response: $dashboardResponse');
      print('Store Orders Response: $storeOrdersResponse');
      
      if (mounted) {
        setState(() {
          // Handle ApiService response wrapping - dashboard endpoint returns direct stats
          _dashboardStats = dashboardResponse['data'] ?? {};
          _homeDeliveryOrders = ordersResponse['data']?['orders'] ?? [];
          _allUsers = usersResponse['data']?['users'] ?? [];
          _storeOrders = storeOrdersResponse['data']?['orders'] ?? [];
          
          // Debug: Print the store orders count from both sources
          print('Dashboard stats pending store orders: ${_dashboardStats['total_pending_store_orders']}');
          print('Store orders array length: ${_storeOrders.length}');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
        ),
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
                );
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
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Deliveries'),
            Tab(icon: Icon(Icons.store), text: 'Store Orders'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
              children: [
                _buildOverviewTab(),
                _buildDeliveriesTab(),
                _buildStoreOrdersTab(),
                _buildUsersTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Patients',
                  _dashboardStats['total_patients']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Doctors',
                  _dashboardStats['total_doctors']?.toString() ?? '0',
                  Icons.medical_services,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Nurses',
                  _dashboardStats['total_nurses']?.toString() ?? '0',
                  Icons.local_hospital,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Medical Stores',
                  _dashboardStats['total_medical_stores']?.toString() ?? '0',
                  Icons.store,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Lab Stores',
                  _dashboardStats['total_lab_stores']?.toString() ?? '0',
                  Icons.science,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Appointments',
                  _dashboardStats['total_appointments']?.toString() ?? '0',
                  Icons.calendar_today,
                  Colors.indigo,
                ),
                _buildStatCard(
                  'Medicine Orders',
                  _dashboardStats['total_medicine_orders']?.toString() ?? '0',
                  Icons.medication,
                  Colors.pink,
                ),
                _buildStatCard(
                  'Lab Orders',
                  _dashboardStats['total_lab_orders']?.toString() ?? '0',
                  Icons.biotech,
                  Colors.cyan,
                ),
                _buildStatCard(
                  'Store Orders',
                  _dashboardStats['total_pending_store_orders']?.toString() ?? '0',
                  Icons.shopping_bag,
                  Colors.deepOrange,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Home Deliveries',
                  Icons.local_shipping,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeDeliveryOrdersScreen(),
                      ),
                    );
                  },
                  badge: _homeDeliveryOrders.length.toString(),
                ),
                _buildActionButton(
                  'Store Orders',
                  Icons.store,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminStoreOrdersScreen(),
                      ),
                    );
                  },
                  badge: _dashboardStats['total_pending_store_orders']?.toString() ?? '0',
                ),
                _buildActionButton(
                  'Medicine Catalog',
                  Icons.medication,
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminMedicineCatalogScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  'Manage Users',
                  Icons.people_outline,
                  Colors.blue,
                  () => _tabController.animateTo(3),
                ),
                _buildActionButton(
                  'View Analytics',
                  Icons.analytics_outlined,
                  Colors.green,
                  () => _tabController.animateTo(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {String? badge}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(icon, color: color),
                if (badge != null && badge != '0')
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badge,
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
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: _homeDeliveryOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Deliveries',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _homeDeliveryOrders.length,
              itemBuilder: (context, index) {
                final order = _homeDeliveryOrders[index];
                return _buildDeliveryOrderCard(order);
              },
            ),
    );
  }

  Widget _buildDeliveryOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = order['total_amount'] ?? 0.0;
    final deliveryAddress = order['delivery_address'] ?? 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text(
                    'PENDING ASSIGNMENT',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Items
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.medication, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['medicine_name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('Qty: ${item['quantity']}'),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deliveryAddress,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAssignStoreDialog(order),
                  icon: const Icon(Icons.assignment, size: 18),
                  label: const Text('Assign Store'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignStoreDialog(Map<String, dynamic> order) async {
    try {
      final storesResponse = await _apiService.get('/api/medical-store/search');
      final stores = (storesResponse['data']?['stores'] as List<dynamic>?) ?? [];
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Assign Order #${order['id']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: stores.isEmpty
                ? const Text('No medical stores available')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return ListTile(
                        leading: const Icon(Icons.store, color: Colors.orange),
                        title: Text(store['name'] ?? 'Unknown'),
                        subtitle: Text('${store['city']}, ${store['state']}'),
                        onTap: () {
                          Navigator.pop(context);
                          _assignOrderToStore(order['id'], store['id']);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stores: $e')),
        );
      }
    }
  }

  Future<void> _assignOrderToStore(int orderId, int storeId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await _apiService.post('/api/admin/assign-order/$orderId', {
        'store_id': storeId,
      });
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to assign order')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildUsersTab() {
    final usersByRole = <String, List<dynamic>>{};
    for (var user in _allUsers) {
      final role = user['role'] ?? 'unknown';
      usersByRole.putIfAbsent(role, () => []);
      usersByRole[role]!.add(user);
    }
    
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Users by Role',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...usersByRole.entries.map((entry) {
            return _buildUserRoleSection(entry.key, entry.value);
          }),
        ],
      ),
    );
  }

  Widget _buildUserRoleSection(String role, List<dynamic> users) {
    final roleInfo = _getRoleInfo(role);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(roleInfo['icon'] as IconData, color: roleInfo['color'] as Color),
        title: Text(
          roleInfo['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${users.length} users'),
        children: users.map((user) {
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: (roleInfo['color'] as Color).withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 20,
                color: roleInfo['color'] as Color,
              ),
            ),
            title: Text(user['email'] ?? 'N/A'),
            subtitle: Text('ID: ${user['id']}'),
            trailing: user['is_active'] == true
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.cancel, color: Colors.red, size: 20),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(String role) {
    switch (role) {
      case 'patient':
        return {
          'title': 'Patients',
          'icon': Icons.people,
          'color': Colors.blue,
        };
      case 'doctor':
        return {
          'title': 'Doctors',
          'icon': Icons.medical_services,
          'color': Colors.green,
        };
      case 'nurse':
        return {
          'title': 'Nurses',
          'icon': Icons.local_hospital,
          'color': Colors.purple,
        };
      case 'medical_store':
        return {
          'title': 'Medical Stores',
          'icon': Icons.store,
          'color': Colors.orange,
        };
      case 'lab_store':
        return {
          'title': 'Lab Stores',
          'icon': Icons.science,
          'color': Colors.teal,
        };
      case 'admin':
        return {
          'title': 'Administrators',
          'icon': Icons.admin_panel_settings,
          'color': Colors.deepPurple,
        };
      default:
        return {
          'title': role.toUpperCase(),
          'icon': Icons.person,
          'color': Colors.grey,
        };
    }
  }

  Widget _buildStoreOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: _storeOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Store Orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _storeOrders.length,
              itemBuilder: (context, index) {
                final order = _storeOrders[index];
                return _buildStoreOrderCard(order);
              },
            ),
    );
  }

  Widget _buildStoreOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = order['total_amount'] ?? 0.0;
    final storeName = order['store_name'] ?? 'Unknown Store';
    final storeCity = order['store_city'] ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (storeCity.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          storeCity,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Order #${order['id']}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),
            
            // Items
            ...items.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.medication, size: 20, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['medicine_name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('Qty: ${item['quantity']}'),
                  ],
                ),
              );
            }),
            
            if (items.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+ ${items.length - 3} more items',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const Divider(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectStoreOrder(order['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approveStoreOrder(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveStoreOrder(int orderId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await _apiService.post('/api/admin/store-orders/$orderId/approve', {});
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store order approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to approve order')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectStoreOrder(int orderId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await _apiService.post('/api/admin/store-orders/$orderId/reject', {
        'reason': reasonController.text.isEmpty ? 'No reason provided' : reasonController.text,
      });
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadDashboardData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to reject order')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildAnalyticsCard(
              'Total System Users',
              _allUsers.length.toString(),
              Icons.people_alt,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            _buildAnalyticsCard(
              'Active Healthcare Providers',
              ((_dashboardStats['total_doctors'] ?? 0) + 
               (_dashboardStats['total_nurses'] ?? 0)).toString(),
              Icons.medical_services,
              Colors.green,
            ),
            const SizedBox(height: 12),
            
            _buildAnalyticsCard(
              'Total Service Providers',
              ((_dashboardStats['total_medical_stores'] ?? 0) + 
               (_dashboardStats['total_lab_stores'] ?? 0)).toString(),
              Icons.business,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            
            _buildAnalyticsCard(
              'Total Transactions',
              ((_dashboardStats['total_medicine_orders'] ?? 0) + 
               (_dashboardStats['total_lab_orders'] ?? 0) +
               (_dashboardStats['total_appointments'] ?? 0)).toString(),
              Icons.receipt_long,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            
            // Pending Actions
            const Text(
              'Pending Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.orange),
                title: const Text('Pending Home Deliveries'),
                trailing: Chip(
                  label: Text(_homeDeliveryOrders.length.toString()),
                  backgroundColor: Colors.orange.shade100,
                ),
                onTap: () => _tabController.animateTo(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
