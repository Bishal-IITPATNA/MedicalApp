import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _apiService = ApiService();
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders to Admin'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshKey++),
          ),
        ],
      ),
      body: FutureBuilder(
        key: ValueKey(_refreshKey),
        future: _apiService.get('/api/medical-store/my-orders'),
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
          final orders = (responseData?['data']?['orders'] ?? responseData?['orders']) as List<dynamic>? ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders you place will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshKey++),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final deliveryStatus = order['delivery_status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final deliveryStatusColor = _getDeliveryStatusColor(deliveryStatus);
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = (order['total_amount'] ?? 0.0).toDouble();
    final orderDate = order['created_at'] ?? order['order_date'];
    final otp = order['delivery_otp'];
    final expectedDeliveryDate = order['expected_delivery_date'];
    final adminNotes = order['admin_notes'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
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
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (status == 'approved') ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: deliveryStatusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: deliveryStatusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            deliveryStatus.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              color: deliveryStatusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(orderDate),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              if (expectedDeliveryDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Expected: ${_formatDeliveryDate(expectedDeliveryDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medication, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} medicine${items.length != 1 ? 's' : ''} ordered',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                ],
              ),
              
              // Show OTP badge if available
              if (otp != null && (status == 'approved' || deliveryStatus == 'out_for_delivery')) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'OTP Available',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Show admin notes badge if available
              if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Admin Notes',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String deliveryStatus) {
    switch (deliveryStatus.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'approved':
        return Colors.blue;
      case 'processing':
        return Colors.indigo;
      case 'dispatched':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.orange;
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDeliveryDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
