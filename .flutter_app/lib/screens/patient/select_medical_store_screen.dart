import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class SelectMedicalStoreScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final String? deliveryType;

  const SelectMedicalStoreScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
    this.deliveryType,
  });

  @override
  State<SelectMedicalStoreScreen> createState() => _SelectMedicalStoreScreenState();
}

class _SelectMedicalStoreScreenState extends State<SelectMedicalStoreScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _availableStores = [];
  bool _isLoading = true;
  String? _error;
  
  int? _selectedStoreId;
  late String _deliveryType;
  
  // Home delivery fields
  bool _homeDeliveryAvailable = false;
  Map<String, dynamic>? _homeDeliveryData;

  @override
  void initState() {
    super.initState();
    _deliveryType = widget.deliveryType ?? 'pickup';
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.post(
        '/api/patient/check-medicine-availability',
        {'items': widget.cartItems},
      );

      print('DEBUG: Availability response: $response');
      print('DEBUG: Available stores: ${response['data']?['available_stores']}');

      if (response['success']) {
        final data = response['data'] as Map<String, dynamic>?;
        setState(() {
          _availableStores = List<Map<String, dynamic>>.from(
            data?['available_stores'] ?? []
          );
          _homeDeliveryAvailable = data?['home_delivery_available'] ?? false;
          if (_homeDeliveryAvailable) {
            _homeDeliveryData = data?['home_delivery'] as Map<String, dynamic>?;
          }
          _isLoading = false;
        });
        print('DEBUG: Loaded ${_availableStores.length} stores');
        print('DEBUG: Home delivery available: $_homeDeliveryAvailable');
      } else {
        throw Exception(response['error'] ?? 'Failed to check availability');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medical store'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final response = await _apiService.post(
        '/api/patient/medicine-orders',
        {
          'items': widget.cartItems,
          'store_id': _selectedStoreId,
          'delivery_type': _deliveryType,
        },
      );

      if (response['success'] && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        final order = data?['order'] as Map<String, dynamic>?;
        if (order != null) {
          // Navigate back with success indicator to clear cart
          Navigator.pop(context, true);
          
          // Navigate to confirmation screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(order: order),
            ),
          );
        } else {
          throw Exception('Order data not found in response');
        }
      } else {
        throw Exception(response['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeAutomaticOrder() async {
    // Place order without store_id - will use automatic routing with home delivery
    try {
      final response = await _apiService.post(
        '/api/patient/medicine-orders',
        {
          'items': widget.cartItems,
          'delivery_type': 'home_delivery', // Force home delivery for automatic routing
        },
      );

      if (response['success'] && mounted) {
        // Navigate back with success indicator to clear cart
        Navigator.pop(context, true);
        
        // Show simple success message for automatic routing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed! Medical stores will be notified.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to patient dashboard using named route
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/patient-dashboard',
          (route) => false,
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Medical Store'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkAvailability,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _availableStores.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No stores have all medicines in stock',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _homeDeliveryAvailable 
                                ? 'But we can deliver to your home!' 
                                : 'Don\'t worry! We can still help you get your medicines.',
                              style: TextStyle(
                                color: _homeDeliveryAvailable ? Colors.green.shade700 : Colors.grey,
                                fontWeight: _homeDeliveryAvailable ? FontWeight.w500 : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            if (_homeDeliveryAvailable && _homeDeliveryData != null) ...[
                              // Home Delivery Option
                              Card(
                                color: Colors.green.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.local_shipping, size: 48, color: Colors.green.shade700),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Home Delivery Available',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _homeDeliveryData!['message'] ?? 'We can deliver to your home',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.green.shade800),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Delivery Details
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Delivery Fee:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                Text('₹${_homeDeliveryData!['delivery_fee'] ?? 0}', 
                                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Estimated Time:', style: TextStyle(fontWeight: FontWeight.w500)),
                                                Text('${_homeDeliveryData!['estimated_delivery_time'] ?? 'TBD'}', 
                                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      if (_homeDeliveryData!['note'] != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _homeDeliveryData!['note'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _placeHomeDeliveryOrder,
                                          icon: const Icon(Icons.delivery_dining),
                                          label: const Text('Order with Home Delivery'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Automatic Home Delivery (fallback)
                              Card(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 40, color: Colors.blue.shade700),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Automatic Home Delivery',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'We\'ll route your order to available medical stores and deliver to your home',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _placeAutomaticOrder,
                                          icon: const Icon(Icons.delivery_dining),
                                          label: const Text('Place Order with Home Delivery'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Go Back & Modify Cart'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Order summary
                        Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Summary',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${widget.cartItems.length} items • Total: ₹${widget.totalAmount.toStringAsFixed(2)}'),
                              const SizedBox(height: 16),
                              
                              // Delivery type selection
                              Text(
                                'Delivery Type',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: const Text('Pickup'),
                                      subtitle: const Text('Collect from store'),
                                      value: 'pickup',
                                      groupValue: _deliveryType,
                                      onChanged: (value) {
                                        setState(() => _deliveryType = value!);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: const Text('Home Delivery'),
                                      subtitle: const Text('OTP required'),
                                      value: 'home_delivery',
                                      groupValue: _deliveryType,
                                      onChanged: (value) {
                                        setState(() => _deliveryType = value!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Stores list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _availableStores.length,
                            itemBuilder: (context, index) {
                              final store = _availableStores[index];
                              final isSelected = _selectedStoreId == store['id'];
                              
                              return Card(
                                elevation: isSelected ? 4 : 1,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : null,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedStoreId = store['id'];
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isSelected 
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_unchecked,
                                              color: isSelected 
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    store['name'] ?? 'Unknown Store',
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (store['address'] != null)
                                                    Text(
                                                      store['address'],
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Available Medicines',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...((store['medicines'] as List?) ?? []).map((medicine) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    medicine['name'] ?? '',
                                                    style: Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${medicine['price']}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: _availableStores.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _selectedStoreId != null ? _placeOrder : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _selectedStoreId != null
                        ? 'Place Order'
                        : 'Select a store to continue',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _placeHomeDeliveryOrder() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      _showSnackBar('User not found');
      return;
    }

    // Map cart items to medicine data for the order
    final orderMedicines = widget.cartItems.map((cartItem) {
      return {
        'medicine_id': cartItem['medicine_id'],
        'quantity': cartItem['quantity']
      };
    }).toList();

    final orderData = {
      'user_id': userId,
      'medicines': orderMedicines,
      'delivery_type': 'home_delivery',
      'home_delivery_data': _homeDeliveryData,
    };

    try {
      final response = await _apiService.post('/api/patient/place-order', orderData);
      if (response['success']) {
        // Clear cart first by popping with success result
        Navigator.pop(context, true);
        
        // Then navigate to confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: response['order']),
          ),
        );
      } else {
        _showSnackBar(response['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      print('Error placing home delivery order: $e');
      _showSnackBar('Error placing order');
    }
  }

  Future<int?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryType = order['delivery_type'] ?? 'pickup';
    final otp = order['delivery_otp'];
    final showOtp = otp != null && otp.toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed Successfully!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order['id']}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Delivery info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        Icons.store,
                        'Medical Store',
                        order['store_name'] ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.local_shipping,
                        'Delivery Type',
                        deliveryType == 'pickup' ? 'Store Pickup' : 'Home Delivery',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Icons.currency_rupee,
                        'Total Amount',
                        '₹${order['total_amount'] ?? 0}',
                      ),
                    ],
                  ),
                ),
              ),
              
              if (showOtp) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                deliveryType == 'pickup' ? 'Pickup OTP' : 'Delivery OTP',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200, width: 2),
                          ),
                          child: Text(
                            otp,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          deliveryType == 'pickup' 
                            ? 'Show this OTP when collecting your order from the store'
                            : 'Share this OTP with the medical store for delivery',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to patient dashboard using named route
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/patient-dashboard',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
