import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class OrderMedicinesScreen extends StatefulWidget {
  
  const OrderMedicinesScreen({super.key});

  @override
  State<OrderMedicinesScreen> createState() => _OrderMedicinesScreenState();
}

class _OrderMedicinesScreenState extends State<OrderMedicinesScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final Map<int, int> _cart = {}; // medicine_id -> quantity
  final Map<String, dynamic> _lowStockMedicinesByName = {}; // For matching low stock medicines to admin catalog
  final Map<String, int> _lowStockCart = {}; // Temporary cart using medicine names
  String _searchQuery = '';
  int _refreshKey = 0;
  bool _isPrePopulated = false;


  @override
  void initState() {
    super.initState();
    // Automatically load and add low stock medicines to cart
    _loadLowStockMedicines();
  }

  Future<void> _loadLowStockMedicines() async {
    try {
      // First, get low stock medicines from medical store
      final lowStockResponse = await _apiService.get('/api/medical-store/low-stock-medicines');
      
      if (lowStockResponse['success']) {
        final lowStockMedicines = (lowStockResponse['data']?['medicines'] ?? lowStockResponse['medicines']) as List<dynamic>? ?? [];
        
        if (lowStockMedicines.isNotEmpty) {
          // Map low stock medicines by name for admin catalog matching
          _lowStockMedicinesByName.clear();
          
          for (var medicine in lowStockMedicines) {
            final name = medicine['name'];
            if (name != null) {
              _lowStockMedicinesByName[name] = medicine;
              
              // Add suggested quantity based on current stock
              final currentStock = medicine['stock_quantity'] ?? 0;
              final suggestedQuantity = currentStock <= 5 ? 50 : 20; // Higher reorder quantities
              
              // Store temporary cart entry with name as key
              _lowStockCart[name] = suggestedQuantity;
            }
          }
          _isPrePopulated = true;
          
          // Now fetch admin catalog and map to correct IDs
          await _loadAdminCatalogForLowStock();
        }
      }
    } catch (e) {
      print('Error loading low stock medicines: $e');
    }
  }

  Future<void> _loadAdminCatalogForLowStock() async {
    try {
      final response = await _apiService.get('/api/medical-store/search');
      final medicines = (response['data']?['medicines'] ?? response['medicines']) as List<dynamic>? ?? [];
      
      // Match low stock medicines by name to admin catalog IDs
      for (var adminMed in medicines) {
        final name = adminMed['name'];
        if (name != null && _lowStockCart.containsKey(name)) {
          // Found matching medicine in admin catalog
          _cart[adminMed['id']] = _lowStockCart[name]!;
        }
      }
      
      // Show message after cart is populated
      if (mounted && _cart.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPrePopulatedMessage();
        });
      }
      
      setState(() {}); // Refresh UI
    } catch (e) {
      print('Error loading admin catalog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load admin catalog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrePopulatedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_cart.length} low stock ${_cart.length == 1 ? 'medicine' : 'medicines'} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: _showCart,
        ),
      ),
    );
  }

  bool _isLowStockMedicine(String? medicineName) {
    return medicineName != null && _lowStockMedicinesByName.containsKey(medicineName);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Medicines'),
        backgroundColor: Colors.green.shade700,
        actions: [
          if (_cart.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _showCart,
                ),
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
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cart.length.toString(),
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
        ],
      ),
      body: Column(
        children: [
          // Pre-populated banner
          if (_isPrePopulated && _cart.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_cart.length} low stock ${_cart.length == 1 ? 'medicine' : 'medicines'} added to cart',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _showCart,
                    child: const Text('View Cart'),
                  ),
                ],
              ),
            ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Available Medicines List
          Expanded(
            child: FutureBuilder(
              key: ValueKey(_refreshKey),
              future: _apiService.get('/api/medical-store/search'),
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
                // Handle response from /api/medical-store/search
                var medicines = (responseData?['data']?['medicines'] ?? 
                               responseData?['medicines']) as List<dynamic>? ?? [];

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  medicines = medicines.where((m) {
                    final name = (m['name'] ?? '').toString().toLowerCase();
                    final manufacturer = (m['manufacturer'] ?? '').toString().toLowerCase();
                    final category = (m['category'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || 
                           manufacturer.contains(_searchQuery) ||
                           category.contains(_searchQuery);
                  }).toList();
                }

                if (medicines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No medicines available'
                              : 'No medicines found',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
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
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              backgroundColor: Colors.green.shade700,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart (${_cart.length})'),
            )
          : null,
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final medicineId = medicine['id'];
    final inCart = _cart.containsKey(medicineId);
    final quantity = _cart[medicineId] ?? 0;

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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medication, color: Colors.green.shade700),
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
                      if (medicine['manufacturer'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'By ${medicine['manufacturer']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (medicine['category'] != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            medicine['category'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${medicine['price'] ?? 0}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Text(' per unit'),
                const Spacer(),
                if (inCart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (quantity > 1) {
                                _cart[medicineId] = quantity - 1;
                              } else {
                                _cart.remove(medicineId);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.remove, size: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _cart[medicineId] = quantity + 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.add, size: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cart[medicineId] = 1;
                      });
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
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

  void _showCart() async {
    if (_cart.isEmpty) return;

    // Fetch full medicine details for cart items
    final response = await _apiService.get('/api/medical-store/search');
    final medicines = (response['data']?['medicines'] ?? response['medicines']) as List<dynamic>? ?? [];
    
    final cartItems = medicines.where((m) => _cart.containsKey(m['id'])).toList();
    
    print('=== Cart Debug Info ===');
    print('Cart map: $_cart');
    print('Total medicines from API: ${medicines.length}');
    print('Cart items found: ${cartItems.length}');
    if (cartItems.isNotEmpty) {
      print('First cart item: ${cartItems[0]}');
    }
    print('=======================');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Cart (${_cart.length} items)',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_isPrePopulated && _lowStockCart.isNotEmpty)
                                Text(
                                  '${_lowStockCart.length} low stock medicines auto-added',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    // Calculate total
                    double total = 0;
                    for (var item in cartItems) {
                      final quantity = _cart[item['id']] ?? 0;
                      final price = (item['price'] ?? 0.0).toDouble();
                      total += quantity * price;
                    }
                    
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              final medicineId = item['id'] as int;
                              // Get current quantity from _cart (will update on setState)
                              final quantity = _cart[medicineId] ?? 0;
                              
                              // Skip items that have been removed from cart
                              if (quantity == 0) {
                                return const SizedBox.shrink();
                              }
                              
                              final price = (item['price'] ?? 0.0).toDouble();
                              final subtotal = quantity * price;

                              return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: _isLowStockMedicine(item['name']) ? Colors.orange.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _isLowStockMedicine(item['name']) 
                                ? BorderSide(color: Colors.orange.shade300, width: 2)
                                : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLowStockMedicine(item['name']))
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Low Stock - Auto Added',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_isLowStockMedicine(item['name'])) const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item['name'] ?? 'Unknown Medicine'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${price.toStringAsFixed(2)} per unit',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item['manufacturer'] != null && item['manufacturer'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item['manufacturer']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _cart.remove(medicineId);
                                        });
                                        setModalState(() {});
                                        if (_cart.isEmpty) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      tooltip: 'Remove from cart',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Quantity controls
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                if (quantity > 1) {
                                                  _cart[medicineId] = quantity - 1;
                                                } else {
                                                  _cart.remove(medicineId);
                                                }
                                              });
                                              setModalState(() {});
                                              if (_cart.isEmpty) {
                                                Navigator.pop(context);
                                              }
                                            },
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              quantity.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _cart[medicineId] = quantity + 1;
                                              });
                                              setModalState(() {});
                                            },
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Subtotal
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          '₹${subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Total section within same StatefulBuilder
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add More'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _placeOrder(cartItems, total);
                            },
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Place Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                    ),
                  ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder(List<dynamic> cartItems, double total) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Prepare order items
      final items = cartItems.map((item) {
        return {
          'medicine_id': item['id'],
          'name': item['name'],
          'quantity': _cart[item['id']],
          'price': item['price'],
        };
      }).toList();

      final response = await _apiService.post('/api/medical-store/order-medicines', {
        'items': items,
        'total_amount': total,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! Admin will process your request.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to place order'),
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
  }
}