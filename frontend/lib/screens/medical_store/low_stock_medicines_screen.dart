import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'order_medicines_screen.dart';

class LowStockMedicinesScreen extends StatefulWidget {
  const LowStockMedicinesScreen({super.key});

  @override
  State<LowStockMedicinesScreen> createState() => _LowStockMedicinesScreenState();
}

class _LowStockMedicinesScreenState extends State<LowStockMedicinesScreen> {
  final _apiService = ApiService();
  int _refreshKey = 0;
  int _threshold = 10;

  @override
  void initState() {
    super.initState();
    _checkLowStock();
  }

  Future<void> _checkLowStock() async {
    try {
      await _apiService.post('/api/medical-store/check-low-stock', {});
    } catch (e) {
      // Silent fail - notifications still created in background
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Medicines'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Set Threshold',
            onSelected: (value) {
              setState(() {
                _threshold = value;
                _refreshKey++;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 5,
                child: Text('Stock ≤ 5'),
              ),
              const PopupMenuItem(
                value: 10,
                child: Text('Stock ≤ 10'),
              ),
              const PopupMenuItem(
                value: 20,
                child: Text('Stock ≤ 20'),
              ),
              const PopupMenuItem(
                value: 50,
                child: Text('Stock ≤ 50'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkLowStock();
              setState(() => _refreshKey++);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        key: ValueKey(_refreshKey),
        future: _apiService.get('/api/medical-store/low-stock-medicines?threshold=$_threshold'),
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
                  Text('Error loading data', style: TextStyle(color: Colors.grey.shade600)),
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
          final medicines = (responseData?['data']?['medicines'] ?? responseData?['medicines']) as List<dynamic>? ?? [];
          final count = responseData?['data']?['count'] ?? responseData?['count'] ?? 0;

          if (medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'All medicines are well stocked!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No medicines below threshold of $_threshold',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Warning Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count ${count == 1 ? 'medicine' : 'medicines'} low on stock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consider ordering from admin',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderMedicinesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _checkLowStock();
                    setState(() => _refreshKey++);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return _buildMedicineCard(medicine);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final stock = medicine['stock_quantity'] ?? 0;
    final isOutOfStock = stock == 0;
    final cardColor = isOutOfStock ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = isOutOfStock ? Colors.red.shade300 : Colors.orange.shade300;
    final iconColor = isOutOfStock ? Colors.red.shade700 : Colors.orange.shade700;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(
                    isOutOfStock ? Icons.block : Icons.warning_amber_rounded,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (medicine['manufacturer'] != null)
                        Text(
                          'By ${medicine['manufacturer']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        stock.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        'units',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (isOutOfStock) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OUT OF STOCK - Order immediately!',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${medicine['price'] ?? 0}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (medicine['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      medicine['category'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
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
}