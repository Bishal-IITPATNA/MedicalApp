import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'manage_tests_screen.dart';
import 'analytics_screen.dart';

class LabStoreDashboard extends StatefulWidget {
  const LabStoreDashboard({super.key});

  @override
  State<LabStoreDashboard> createState() => _LabStoreDashboardState();
}

class _LabStoreDashboardState extends State<LabStoreDashboard> {
  final _authService = AuthService();
  final _apiService = ApiService();
  int _selectedIndex = 0;
  String _labName = '';
  
  @override
  void initState() {
    super.initState();
    _loadLabData();
  }

  Future<void> _loadLabData() async {
    try {
      final response = await _apiService.get('/api/lab-store/profile');
      if (mounted && response['success'] == true) {
        final data = response['data'];
        setState(() {
          _labName = data['name'] ?? 'Lab Store';
        });
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
              child: const Icon(Icons.science, color: Colors.white),
            ),
          ),
          title: Text(_selectedIndex == 0 ? 'Lab Store Dashboard' : _getTitleForIndex()),
          backgroundColor: Colors.purple.shade700,
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
                      builder: (context) => const LabStoreAnalyticsScreen(),
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
                } else if (value == 'settings') {
                  setState(() => _selectedIndex = 4);
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
        ),
        body: _buildBody(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.science),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  String _getTitleForIndex() {
    switch (_selectedIndex) {
      case 1:
        return 'Manage Tests';
      case 2:
        return 'Orders';
      case 3:
        return 'Profile';
      case 4:
        return 'Settings';
      default:
        return 'Lab Store Dashboard';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildTestsTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildProfileTab();
      case 4:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _labName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder(
      future: _apiService.get('/api/lab-store/dashboard'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final totalTests = data['total_tests_done'] ?? 0;
        final totalPatients = data['total_patients_served'] ?? 0;
        final totalRevenue = data['total_revenue'] ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tests Done',
                    totalTests.toString(),
                    Icons.science,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Patients',
                    totalPatients.toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Revenue',
              '₹${totalRevenue.toStringAsFixed(2)}',
              Icons.currency_rupee,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Orders',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        FutureBuilder(
          future: _apiService.get('/api/lab-store/orders'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final response = snapshot.data;
            
            // Check if API call was successful
            if (response == null || response['success'] != true) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading orders',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final data = response['data'];
            final orders = (data?['orders'] as List<dynamic>?) ?? [];

            if (orders.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
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

            // Show only last 5 orders
            final recentOrders = orders.take(5).toList();

            return Column(
              children: recentOrders.map((order) => _buildOrderCard(order)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final orderId = order['id'];
    final totalAmount = order['total_amount'] ?? 0.0;
    final items = (order['items'] as List<dynamic>?) ?? [];
    
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'sample_collected':
        statusColor = Colors.blue;
        statusIcon = Icons.biotech;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      case 'declined':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text('Order #$orderId'),
        subtitle: Text('${items.length} test(s) • ₹${totalAmount.toStringAsFixed(2)}'),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          side: BorderSide(color: statusColor.withOpacity(0.3)),
        ),
        onTap: () => _showOrderDetails(order),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${order['status']}'),
              Text('Total: ₹${order['total_amount']}'),
              const SizedBox(height: 16),
              const Text('Tests:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(order['items'] as List<dynamic>).map((item) {
                final test = item['test'] as Map<String, dynamic>?;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• ${test?['name'] ?? 'Unknown test'}'),
                );
              }),
            ],
          ),
        ),
        actions: [
          if (order['status'] == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order['id'], 'declined');
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order['id'], 'accepted');
              },
              child: const Text('Accept'),
            ),
          ] else if (order['status'] == 'accepted') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order['id'], 'sample_collected');
              },
              child: const Text('Sample Collected'),
            ),
          ] else if (order['status'] == 'sample_collected') ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadReport(order['id']);
              },
              child: const Text('Upload Report'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      await _apiService.put('/api/lab-store/orders/$orderId', {'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $status successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _uploadReport(int orderId) {
    final findingsController = TextEditingController();
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: findingsController,
                decoration: const InputDecoration(labelText: 'Findings'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
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
              try {
                await _apiService.post('/api/lab-store/reports', {
                  'order_id': orderId,
                  'findings': findingsController.text,
                  'remarks': remarksController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report uploaded successfully')),
                  );
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsTab() {
    return const ManageTestsScreen();
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder(
        future: _apiService.get('/api/lab-store/orders'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final response = snapshot.data;
          
          // Check if API call was successful
          if (response == null || response['success'] != true) {
            final errorMessage = response?['error'] ?? 'Failed to load orders';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final data = response['data'];
          final orders = (data?['orders'] as List<dynamic>?) ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildDetailedOrderCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildDetailedOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final orderId = order['id'];
    final totalAmount = order['total_amount'] ?? 0.0;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final testDate = order['test_date'] ?? '';
    final collectionAddress = order['collection_address'] ?? 'N/A';
    
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'sample_collected':
        statusColor = Colors.blue;
        statusIcon = Icons.biotech;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      case 'declined':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

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
                  'Order #$orderId',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) {
              final test = item['test'] as Map<String, dynamic>?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.science, size: 20, color: Colors.purple.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(test?['name'] ?? 'Unknown test'),
                    ),
                    Text(
                      '₹${item['price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (testDate.isNotEmpty)
                        Text(
                          'Test Date: ${testDate.split('T')[0]}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      Text(
                        'Address: $collectionAddress',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (status == 'pending' || status == 'accepted' || status == 'sample_collected') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (status == 'pending') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateOrderStatus(orderId, 'declined'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(orderId, 'accepted'),
                        child: const Text('Accept'),
                      ),
                    ),
                  ] else if (status == 'accepted') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(orderId, 'sample_collected'),
                        icon: const Icon(Icons.biotech),
                        label: const Text('Sample Collected'),
                      ),
                    ),
                  ] else if (status == 'sample_collected') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadReport(orderId),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder(
      future: _apiService.get('/api/lab-store/profile'),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final responseData = snapshot.data;
        final profile = responseData?['data'] ?? {};

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
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.science, size: 50, color: Colors.purple.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile['name'] ?? 'Lab Store',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (profile['phone'] != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            profile['phone'],
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.phone, 'Phone', profile['phone'] ?? 'Not provided'),
                    _buildInfoRow(Icons.location_on, 'Address', profile['address'] ?? 'Not provided'),
                    _buildInfoRow(Icons.location_city, 'City', profile['city'] ?? 'Not provided'),
                    _buildInfoRow(Icons.map, 'State', profile['state'] ?? 'Not provided'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        // Notifications Section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive notifications about orders and updates'),
          value: true,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings coming soon!')),
            );
          },
          secondary: const Icon(Icons.notifications),
        ),
        SwitchListTile(
          title: const Text('Email Notifications'),
          subtitle: const Text('Receive notifications via email'),
          value: true,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings coming soon!')),
            );
          },
          secondary: const Icon(Icons.email),
        ),
        const Divider(),

        // Appearance Section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme'),
          value: false,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dark mode coming soon!')),
            );
          },
          secondary: const Icon(Icons.dark_mode),
        ),
        const Divider(),

        // Privacy & Security Section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Privacy & Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('Change Password'),
          leading: const Icon(Icons.lock),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _showChangePasswordDialog();
          },
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          leading: const Icon(Icons.privacy_tip),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy policy coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Terms & Conditions'),
          leading: const Icon(Icons.description),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terms & conditions coming soon')),
            );
          },
        ),
        const Divider(),

        // About Section
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: const Text('App Version'),
          subtitle: const Text('1.0.0'),
          leading: const Icon(Icons.info),
        ),
        ListTile(
          title: const Text('Help & Support'),
          leading: const Icon(Icons.help),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support contact: support@labstore.com')),
            );
          },
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon!'),
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

