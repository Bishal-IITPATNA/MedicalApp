import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'find_doctor_screen.dart';
import 'find_nurse_screen.dart';
import 'buy_medicine_screen.dart';
import 'lab_test_booking_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'appointment_detail_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _authService = AuthService();
  final _apiService = ApiService();
  int _selectedIndex = 0;
  String _patientName = '';
  int _appointmentsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      if (response['success'] && mounted) {
        final profileData = response['data']['profile'];
        if (profileData != null) {
          setState(() {
            _patientName = profileData['name'] ?? 'Patient';
          });
        }
      }
    } catch (e) {
      // Silently fail, will show default greeting
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
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: const Text('Patient Dashboard'),
        actions: [
          FutureBuilder(
            future: _apiService.get('/api/notifications/'),
            builder: (context, snapshot) {
              int unreadCount = 0;
              
              if (snapshot.hasData) {
                final data = snapshot.data;
                final responseData = data?['data'];
                final notifications = responseData?['notifications'] as List<dynamic>? ?? [];
                unreadCount = notifications.where((n) => n['is_read'] == false).length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      ).then((_) => setState(() {})); // Refresh on return
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
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
                          unreadCount > 9 ? '9+' : '$unreadCount',
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
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.science),
            label: 'Lab Tests',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildAppointmentsTab();
      case 2:
        return _buildMedicinesTab();
      case 3:
        return _buildLabTestsTab();
      default:
        return _buildHomeTab();
    }
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
      // Refresh appointments when navigating to appointments tab
      if (index == 1) {
        _appointmentsRefreshKey++;
      }
    });
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName.isEmpty 
                      ? 'Hello, Patient!' 
                      : 'Hello, $_patientName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How can we help you today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                'Find Doctor',
                Icons.person_search,
                Colors.blue,
                () {
                  _showFindDoctorDialog();
                },
              ),
              _buildQuickActionCard(
                'Find Nurse',
                Icons.local_hospital,
                Colors.green,
                () {
                  _showFindNurseDialog();
                },
              ),
              _buildQuickActionCard(
                'Buy Medicine',
                Icons.medication,
                Colors.orange,
                () {
                  _showBuyMedicineDialog();
                },
              ),
              _buildQuickActionCard(
                'Book Lab Test',
                Icons.science,
                Colors.purple,
                () {
                  _showBookLabTestDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return FutureBuilder(
      key: ValueKey(_appointmentsRefreshKey),
      future: _apiService.get('/api/patient/appointments'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('Error fetching appointments: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final data = snapshot.data;
        print('Appointments data received: $data');
        
        // Check if API call was successful
        if (data == null || data['success'] != true) {
          final errorMessage = data?['error'] ?? 'Failed to load appointments';
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _appointmentsRefreshKey++),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // API service wraps response in 'data', so appointments are at data['appointments']
        final responseData = data['data'];
        final appointments = responseData?['appointments'] as List<dynamic>? ?? [];
        print('Appointments count: ${appointments.length}');
        
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No appointments yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book your first appointment with a doctor',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showFindDoctorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Find Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'pending';
    final appointmentDate = appointment['appointment_date'];
    final appointmentTime = appointment['appointment_time'];
    final fee = appointment['consultation_fee'] ?? 0.0;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default: // pending
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(appointment: appointment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.teal.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doctor Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '₹$fee',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            appointmentDate ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            appointmentTime ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment['symptoms'] != null && appointment['symptoms'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Symptoms: ${appointment['symptoms']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder(
        future: _apiService.get('/api/patient/medicine-orders'),
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
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final response = snapshot.data;
          final data = response?['data'];
          final orders = (data?['orders'] as List<dynamic>?) ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Medicine Orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your medicine purchases will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showBuyMedicineDialog,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Buy Medicines'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildMedicineOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicineOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final createdAt = order['created_at'] ?? '';
    final totalAmount = order['total_amount'] ?? 0.0;
    final deliveryType = order['delivery_type'] ?? 'pickup';
    final storeName = order['store_name'] ?? 'N/A';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final bill = order['bill'];
    final deliveryOtp = order['delivery_otp'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'dispatched':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
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
            
            // Items
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medication, size: 20, color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['medicine_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Qty: ${item['quantity']} × ₹${item['price']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          deliveryType == 'home_delivery' ? Icons.home : Icons.store,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deliveryType == 'home_delivery' ? 'Home Delivery' : 'Pickup',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt.split('T')[0],
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
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
            
            // OTP Display (when dispatched for home delivery)
            if (deliveryOtp != null && deliveryType == 'home_delivery' && status == 'dispatched') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 24, color: Colors.purple.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery OTP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deliveryOtp,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this OTP with delivery person',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Bill Section
            if (bill != null && status == 'completed') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showMedicineBillDetails(bill),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabTestsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder(
        future: _apiService.get('/api/patient/lab-orders'),
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
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final response = snapshot.data;
          print('Lab orders response: $response'); // Debug
          
          // Handle API service wrapper
          List<dynamic> orders = [];
          if (response != null && response['success'] == true) {
            final data = response['data'] as Map<String, dynamic>?;
            print('Lab orders data: $data'); // Debug
            orders = (data?['orders'] as List<dynamic>?) ?? [];
          }
          
          print('Found ${orders.length} lab orders'); // Debug

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Lab Test Orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your lab test bookings will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showBookLabTestDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Book Lab Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildLabTestOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildLabTestOrderCard(Map<String, dynamic> order) {
    print('Building lab test order card for: $order'); // Debug
    
    final orderId = order['id'] ?? 0;
    final status = order['status'] ?? 'pending';
    final orderDate = order['order_date'] ?? '';
    final testDate = order['test_date'] ?? '';
    final testTime = order['test_time'] ?? '';
    final totalAmount = (order['total_amount'] ?? 0.0).toDouble();
    final collectionAddress = order['collection_address'] ?? '';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final bill = order['bill'];
    
    print('Order $orderId has ${items.length} items'); // Debug

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'sample_collected':
        statusColor = Colors.blue;
        statusIcon = Icons.local_hospital;
        break;
      case 'completed':
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
      case 'declined':
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (testDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Test Date: ${testDate.split('T')[0]}${testTime.isNotEmpty ? ' at ${testTime.substring(0, 5)}' : ''}',
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
                        status.toUpperCase().replaceAll('_', ' '),
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
            
            // Items
            ...items.map((item) {
              final test = item['test'];
              final testName = test?['name'] ?? 'Unknown Test';
              final testPrice = item['price'] ?? 0.0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.science, size: 20, color: Colors.purple.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        testName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '₹${testPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (collectionAddress.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Home Collection',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        orderDate.split('T')[0],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
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
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Bill Section
            if (bill != null && status == 'completed') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showLabBillDetails(bill),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 24, color: Colors.purple.shade700),
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
                                color: Colors.purple.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bill['bill_number'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.purple.shade700),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Bill viewing methods
  void _showMedicineBillDetails(Map<String, dynamic> bill) {
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
            const Text('Medicine Bill'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBillRow('Bill Number', bill['bill_number'] ?? 'N/A', bold: true),
              _buildBillRow('Date', _formatBillDate(bill['created_at'] ?? '')),
              _buildBillRow('Patient', bill['patient_name'] ?? 'N/A'),
              _buildBillRow('Store', bill['medical_store_name'] ?? 'N/A'),
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

  void _showLabBillDetails(Map<String, dynamic> bill) {
    final items = (bill['items'] as List<dynamic>?) ?? [];
    final subtotal = (bill['subtotal'] ?? 0.0).toDouble();
    final gstAmount = (bill['tax_amount'] ?? 0.0).toDouble();
    final totalAmount = (bill['total_amount'] ?? 0.0).toDouble();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('Lab Test Bill'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBillRow('Bill Number', bill['bill_number'] ?? 'N/A', bold: true),
              _buildBillRow('Date', _formatBillDate(bill['created_at'] ?? '')),
              _buildBillRow('Patient', bill['patient_name'] ?? 'N/A'),
              _buildBillRow('Lab Store', bill['lab_store_name'] ?? 'N/A'),
              const Divider(height: 24),
              
              const Text(
                'Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['test_name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '₹${(item['price'] ?? 0.0).toStringAsFixed(2)}',
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

  // Navigation methods for quick actions
  void _showFindDoctorDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindDoctorScreen()),
    );
  }

  void _showFindNurseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindNurseScreen()),
    );
  }

  void _showBuyMedicineDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BuyMedicineScreen()),
    );
  }

  void _showBookLabTestDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LabTestBookingScreen()),
    );
  }
}
