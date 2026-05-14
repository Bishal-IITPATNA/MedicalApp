import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MedicinePaymentScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final String orderDetails;
  
  const MedicinePaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderDetails,
  });

  @override
  State<MedicinePaymentScreen> createState() => _MedicinePaymentScreenState();
}

class _MedicinePaymentScreenState extends State<MedicinePaymentScreen> {
  final _apiService = ApiService();
  late Razorpay _razorpay;
  bool _isProcessing = false;
  
  // Breakdown details
  double subtotal = 0.0;
  double gst = 0.0;
  double deliveryCharges = 0.0;
  double total = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchOrderDetails();
  }
  
  Future<void> _fetchOrderDetails() async {
    try {
      // Fetch order details to get the breakdown
      // This would typically come from the previous screen or we fetch from API
      // For now, we'll calculate based on the amount passed
      // In a real scenario, you'd fetch the full order details from /api/patient/medicine-orders/<id>
    } catch (e) {
      print('Error fetching order details: $e');
    }
  }
  
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);
    
    try {
      // Create Razorpay order from backend
      final response = await _apiService.post(
        '/api/payments/razorpay/create-order',
        {
          'amount': widget.amount,
          'related_type': 'medicine_order',
          'related_id': widget.orderId,
          'description': 'Medicine Order Payment',
        },
      );
      
      if (!response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response['error']}')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }
      
      final razorpayOrderId = response['razorpay_order_id'];
      final razorpayKey = response['razorpay_key'];
      
      // Open Razorpay checkout
      var options = {
        'key': razorpayKey,
        'order_id': razorpayOrderId,
        'amount': (widget.amount * 100).toInt(), // Amount in paise
        'name': 'Medical App',
        'description': widget.orderDetails,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'external': {
          'wallets': ['paytm', 'googlepay', 'phonepe'],
        },
      };
      
      try {
        _razorpay.open(options);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
      
      setState(() => _isProcessing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isProcessing = false);
    }
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Verify payment signature on backend
    try {
      final verifyResponse = await _apiService.post(
        '/api/payments/razorpay/verify',
        {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
        },
      );
      
      if (verifyResponse['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context, true); // Return success to previous screen
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification failed: ${verifyResponse['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID:'),
                        Text('#${widget.orderId}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Description:'),
                        Expanded(
                          child: Text(
                            widget.orderDetails,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Price Breakdown',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('₹${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST (5%):'),
                        Text('₹${gst.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Charges:'),
                        Text(
                          '₹${deliveryCharges.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: const Text('Razorpay'),
              subtitle: const Text('UPI, Cards, Wallets, NetBanking'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: _isProcessing ? null : _initiatePayment,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _initiatePayment,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _isProcessing ? 'Processing...' : 'Pay ₹${widget.amount.toStringAsFixed(2)}',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
