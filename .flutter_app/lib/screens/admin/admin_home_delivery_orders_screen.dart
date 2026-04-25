import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminHomeDeliveryOrdersScreen extends StatefulWidget {
  const AdminHomeDeliveryOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeDeliveryOrdersScreen> createState() => _AdminHomeDeliveryOrdersScreenState();
}

class _AdminHomeDeliveryOrdersScreenState extends State<AdminHomeDeliveryOrdersScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<dynamic> pendingOrders = [];
  List<dynamic> assignedOrders = [];
  List<dynamic> completedOrders = [];
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      final response = await _apiService.get('/api/admin/home-delivery-orders');
      
      if (response['success']) {
        final data = response['data'];
        setState(() {
          pendingOrders = data['pending_orders'] ?? [];
          assignedOrders = data['assigned_orders'] ?? [];
          completedOrders = data['completed_orders'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = response['error'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load orders: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> _assignOrderToStore(int orderId) async {
    final storeIdController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Store'),
        content: TextField(
          controller: storeIdController,
          decoration: const InputDecoration(
            labelText: 'Store ID',
            hintText: 'Enter medical store ID',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final storeId = int.tryParse(storeIdController.text);
              if (storeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid store ID')),
                );
                return;
              }
              
              final response = await _apiService.post(
                '/api/admin/assign-order/$orderId',
                {'store_id': storeId},
              );
              
              if (response['success']) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order assigned successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(response['error'] ?? 'Failed to assign order')),
                );
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      _loadOrders();
    }
  }
  
  Future<void> _completeDelivery(int orderId, String otp) async {
    final response = await _apiService.post(
      '/api/admin/patient-orders/$orderId/complete-delivery',
      {'otp': otp},
    );
    
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed successfully')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? 'Failed to complete delivery')),
      );
    }
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order, {bool showAssignButton = false, bool showCompleteButton = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                Chip(
                  label: Text(
                    order['status'] ?? 'pending',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(order['status']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${order['patient_id']}'),
            if (order['store_name'] != null) Text('Store: ${order['store_name']}'),
            Text('Amount: ₹${order['total_amount'] ?? 0}'),
            Text('Delivery Address: ${order['delivery_address'] ?? 'N/A'}'),
            if (order['delivery_otp'] != null) Text('OTP: ${order['delivery_otp']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (order['bill'] != null) ...[
              const Divider(),
              Text('Bill: ${order['bill']['bill_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Bill Amount: ₹${order['bill']['total_amount']}'),
            ],
            if (showAssignButton || showCompleteButton) const SizedBox(height: 12),
            if (showAssignButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _assignOrderToStore(order['id']),
                  child: const Text('Assign to Store'),
                ),
              ),
            if (showCompleteButton)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final otpController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Complete Delivery'),
                        content: TextField(
                          controller: otpController,
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: '6-digit OTP',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _completeDelivery(order['id'], otpController.text);
                            },
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Complete Delivery'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade200;
      case 'confirmed':
      case 'accepted':
        return Colors.blue.shade200;
      case 'dispatched':
      case 'out_for_delivery':
        return Colors.purple.shade200;
      case 'delivered':
      case 'completed':
        return Colors.green.shade200;
      case 'cancelled':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Delivery Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pendingOrders.length})'),
            Tab(text: 'Assigned (${assignedOrders.length})'),
            Tab(text: 'Completed (${completedOrders.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Pending orders
                      pendingOrders.isEmpty
                          ? const Center(child: Text('No pending orders'))
                          : ListView.builder(
                              itemCount: pendingOrders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(
                                  pendingOrders[index],
                                  showAssignButton: true,
                                );
                              },
                            ),
                      // Assigned orders
                      assignedOrders.isEmpty
                          ? const Center(child: Text('No assigned orders'))
                          : ListView.builder(
                              itemCount: assignedOrders.length,
                              itemBuilder: (context, index) {
                                final order = assignedOrders[index];
                                return _buildOrderCard(
                                  order,
                                  showCompleteButton: order['status'] == 'out_for_delivery' || order['status'] == 'dispatched',
                                );
                              },
                            ),
                      // Completed orders
                      completedOrders.isEmpty
                          ? const Center(child: Text('No completed orders'))
                          : ListView.builder(
                              itemCount: completedOrders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(completedOrders[index]);
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
