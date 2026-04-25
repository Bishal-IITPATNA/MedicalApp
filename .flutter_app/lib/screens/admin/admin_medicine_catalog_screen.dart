import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class AdminMedicineCatalogScreen extends StatefulWidget {
  const AdminMedicineCatalogScreen({Key? key}) : super(key: key);

  @override
  State<AdminMedicineCatalogScreen> createState() => _AdminMedicineCatalogScreenState();
}

class _AdminMedicineCatalogScreenState extends State<AdminMedicineCatalogScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> medicines = [];
  bool isLoading = true;
  String? error;
  String? searchName;
  String? searchCategory;
  
  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }
  
  Future<void> _loadCatalog() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    
    try {
      String url = '/api/admin/medicine-catalog';
      List<String> params = [];
      if (searchName != null && searchName!.isNotEmpty) {
        params.add('name=$searchName');
      }
      if (searchCategory != null && searchCategory!.isNotEmpty) {
        params.add('category=$searchCategory');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      // Debug: Print the response to see the structure
      print('API Response: $response');
      
      if (response['success']) {
        setState(() {
          // Handle nested response structure from API service
          final responseData = response['data'];
          if (responseData != null && responseData['success'] == true) {
            medicines = responseData['data']['medicines'] ?? [];
            print('Loaded ${medicines.length} medicines from nested structure');
          } else {
            medicines = response['data']['medicines'] ?? [];
            print('Loaded ${medicines.length} medicines from direct structure');
          }
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
        error = 'Failed to load catalog: $e';
        isLoading = false;
      });
    }
  }
  
  void _performSearch() {
    setState(() {
      searchName = _searchController.text;
    });
    _loadCatalog();
  }
  
  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final manufacturerController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    bool requiresPrescription = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medicine to Catalog'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price *',
                          border: OutlineInputBorder(),
                          prefixText: '₹ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Requires Prescription'),
                  value: requiresPrescription,
                  onChanged: (value) {
                    setDialogState(() {
                      requiresPrescription = value ?? false;
                    });
                  },
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
                if (nameController.text.isEmpty || priceController.text.isEmpty || stockController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                try {
                  final response = await _apiService.post('/api/admin/medicine-catalog', {
                    'name': nameController.text,
                    'manufacturer': manufacturerController.text.isEmpty ? null : manufacturerController.text,
                    'category': categoryController.text.isEmpty ? null : categoryController.text,
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'stock_quantity': int.tryParse(stockController.text) ?? 0,
                    'requires_prescription': requiresPrescription,
                  });

                  if (response['success']) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medicine added to catalog successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCatalog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response['error'] ?? 'Failed to add medicine')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(Map<String, dynamic> medicine) {
    final nameController = TextEditingController(text: medicine['name'] ?? '');
    final manufacturerController = TextEditingController(text: medicine['manufacturer'] ?? '');
    final categoryController = TextEditingController(text: medicine['category'] ?? '');
    final descriptionController = TextEditingController(text: medicine['description'] ?? '');
    final priceController = TextEditingController(text: (medicine['price'] ?? 0).toString());
    final stockController = TextEditingController(text: (medicine['stock_quantity'] ?? 0).toString());
    bool requiresPrescription = medicine['requires_prescription'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined),
                      const SizedBox(width: 8),
                      const Text(
                        'Edit Medicine',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price *',
                            border: OutlineInputBorder(),
                            prefixText: '₹',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Requires Prescription'),
                    value: requiresPrescription,
                    onChanged: (value) {
                      setState(() {
                        requiresPrescription = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateMedicine(
                          medicine['id'],
                          nameController.text,
                          manufacturerController.text,
                          categoryController.text,
                          descriptionController.text,
                          priceController.text,
                          stockController.text,
                          requiresPrescription,
                        ),
                        child: const Text('Update Medicine'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateMedicine(
    int medicineId,
    String name,
    String manufacturer,
    String category,
    String description,
    String price,
    String stock,
    bool requiresPrescription,
  ) async {
    if (name.trim().isEmpty || price.trim().isEmpty || stock.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/admin/medicine-catalog/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name.trim(),
          'manufacturer': manufacturer.trim(),
          'category': category.trim(),
          'description': description.trim(),
          'price': double.parse(price),
          'stock_quantity': int.parse(stock),
          'requires_prescription': requiresPrescription,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine updated successfully!')),
        );
        _loadCatalog(); // Refresh the list
      } else {
        throw Exception('Failed to update medicine');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating medicine: $e')),
      );
    }
  }

  void _deleteMedicine(Map<String, dynamic> medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Medicine'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${medicine['name']}"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. The medicine will be removed from the catalog.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _confirmDeleteMedicine(medicine['id']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteMedicine(int medicineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/admin/medicine-catalog/$medicineId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine deleted successfully!')),
        );
        _loadCatalog(); // Refresh the list
      } else {
        throw Exception('Failed to delete medicine');
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting medicine: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Catalog'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchName = null;
                    });
                    _loadCatalog();
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
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
                        onPressed: _loadCatalog,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : medicines.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No medicines found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          SizedBox(height: 8),
                          Text('Medicines from medical stores will appear here', 
                               style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCatalog,
                      child: ListView.builder(
                        itemCount: medicines.length,
                        itemBuilder: (context, index) {
                          final medicine = medicines[index];
                          final bool requiresPrescription = medicine['requires_prescription'] ?? false;
                          final int stockQuantity = medicine['stock_quantity'] ?? 0;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: requiresPrescription ? Colors.orange.shade100 : Colors.green.shade100,
                                child: Icon(
                                  requiresPrescription ? Icons.medical_services : Icons.medication,
                                  color: requiresPrescription ? Colors.orange.shade700 : Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                medicine['name'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditMedicineDialog(medicine);
                                  } else if (value == 'delete') {
                                    _deleteMedicine(medicine);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (medicine['category'] != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            medicine['category'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      if (requiresPrescription)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Rx Required',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (medicine['manufacturer'] != null)
                                    Text(
                                      'Manufacturer: ${medicine['manufacturer']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  if (medicine['store_name'] != null) ...[
                                    Text(
                                      'Available at: ${medicine['store_name']}${medicine['store_city'] != null ? ' (${medicine['store_city']})' : ''}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${medicine['price'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Stock: $stockQuantity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: stockQuantity < 20 ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }
}
