import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminStoreOrdersScreen extends StatefulWidget {
  const AdminStoreOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminStoreOrdersScreen> createState() => _AdminStoreOrdersScreenState();
}

class _AdminStoreOrdersScreenState extends State<AdminStoreOrdersScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> orders = [];
  bool isLoading = true;
  String? error;
  String? statusFilter;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      String url = '/api/admin/store-orders';
      if (statusFilter != null) {
        url += '?status=$statusFilter';
      }
      
      final response = await _apiService.get(url);
      
      if (response['success']) {
        setState(() {
          orders = response['data']['orders'] ?? [];
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
  
  Future<void> _approveOrder(int orderId) async {
    final response = await _apiService.post(
      '/api/admin/store-orders/$orderId/approve',
      {},
    );
    
    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order approved successfully')),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? 'Failed to approve order')),
      );
    }
  }
  
  Future<void> _rejectOrder(int orderId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
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
    
    if (confirmed == true) {
      final response = await _apiService.post(
        '/api/admin/store-orders/$orderId/reject',
        {'reason': reasonController.text},
      );
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to reject order')),
        );
      }
    }
  }
  
  Future<void> _updateDeliveryStatus(int orderId) async {
    final statuses = ['processing', 'dispatched', 'out_for_delivery', 'delivered'];
    String? selectedStatus;
    final notesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Delivery Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Delivery Status'),
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () async {
                      final response = await _apiService.post(
                        '/api/admin/store-orders/$orderId/update-delivery-status',
                        {
                          'delivery_status': selectedStatus,
                          'notes': notesController.text,
                        },
                      );
                      
                      if (response['success']) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response['error'] ?? 'Failed to update status')),
                        );
                      }
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery status updated')),
      );
      _loadOrders();
    }
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final deliveryStatus = order['delivery_status'] as String?;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = (order['total_amount'] ?? 0.0).toDouble();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order['store_name'] ?? 'Unknown Store'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    status ?? 'pending',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(status),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Order Date: ${order['order_date'] ?? 'N/A'}'),
            if (deliveryStatus != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Delivery: '),
                  Chip(
                    label: Text(
                      deliveryStatus.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: _getDeliveryStatusColor(deliveryStatus),
                  ),
                ],
              ),
            ],
            if (order['expected_delivery_date'] != null) ...[
              const SizedBox(height: 4),
              Text('Expected: ${order['expected_delivery_date']}'),
            ],
            const SizedBox(height: 8),
            Text(
              '${items.length} medicine${items.length != 1 ? 's' : ''} ordered',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        children: [
          _buildStoreDetails(order),
          const SizedBox(height: 16),
          _buildMedicinesList(items),
          const SizedBox(height: 16),
          _buildOrderActions(order),
        ],
      ),
    );
  }

  Widget _buildStoreDetails(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Store Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Name: ${order['store_name'] ?? 'N/A'}'),
          if (order['store_email'] != null)
            Text('Email: ${order['store_email']}'),
          if (order['store_phone'] != null)
            Text('Phone: ${order['store_phone']}'),
          if (order['store_address'] != null)
            Text('Address: ${order['store_address']}'),
          if (order['store_city'] != null && order['store_state'] != null)
            Text('Location: ${order['store_city']}, ${order['store_state']}'),
          if (order['store_pincode'] != null)
            Text('Pincode: ${order['store_pincode']}'),
          if (order['store_license'] != null)
            Text('License: ${order['store_license']}'),
          if (order['admin_notes'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Admin Notes: ${order['admin_notes']}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicinesList(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Medicines Ordered',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map<Widget>((item) {
            final quantity = item['quantity'] ?? 0;
            final price = (item['price'] ?? 0.0).toDouble();
            final subtotal = quantity * price;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['medicine_name'] ?? 'Unknown Medicine',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty: $quantity',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹${price.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                '₹${items.fold<double>(0, (sum, item) => sum + ((item['quantity'] ?? 0) * (item['price'] ?? 0.0))).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final orderId = order['id'] as int;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Action buttons based on status
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveOrder(orderId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectOrder(orderId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'approved') ...[
            ElevatedButton(
              onPressed: () => _updateDeliveryStatus(orderId),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Update Delivery Status'),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade200;
      case 'approved':
        return Colors.blue.shade200;
      case 'completed':
        return Colors.green.shade200;
      case 'rejected':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
  
  Color _getDeliveryStatusColor(String? status) {
    switch (status) {
      case 'processing':
        return Colors.blue.shade100;
      case 'dispatched':
        return Colors.purple.shade100;
      case 'out_for_delivery':
        return Colors.orange.shade100;
      case 'delivered':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Orders'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                statusFilter = value == 'all' ? null : value;
              });
              _loadOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Orders')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
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
              : orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(orders[index]);
                        },
                      ),
                    ),
    );
  }
}
