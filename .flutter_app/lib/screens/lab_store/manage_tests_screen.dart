import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageTestsScreen extends StatefulWidget {
  const ManageTestsScreen({super.key});

  @override
  State<ManageTestsScreen> createState() => _ManageTestsScreenState();
}

class _ManageTestsScreenState extends State<ManageTestsScreen> {
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder(
          future: _apiService.get('/api/lab-store/tests'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final response = snapshot.data;
            final data = response?['data'];
            final tests = (data?['tests'] as List<dynamic>?) ?? [];

            if (tests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.science_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No Tests Available',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddTestDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Test'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tests.length + 1,
              itemBuilder: (context, index) {
                if (index == tests.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _showAddTestDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Test'),
                      ),
                    ),
                  );
                }
                return _buildTestCard(tests[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final isAvailable = test['is_available'] ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                Expanded(
                  child: Text(
                    test['name'] ?? 'Unknown Test',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Switch(
                      value: isAvailable,
                      onChanged: (value) => _toggleAvailability(test['id'], value),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditTestDialog(test);
                        } else if (value == 'delete') {
                          _deleteTest(test['id']);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (test['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                test['description'],
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (test['category'] != null)
                  Chip(
                    label: Text(test['category']),
                    backgroundColor: Colors.blue.shade50,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                if (test['sample_type'] != null)
                  Chip(
                    label: Text(test['sample_type']),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade200),
                    avatar: const Icon(Icons.bloodtype, size: 16),
                  ),
                if (test['report_delivery_time'] != null)
                  Chip(
                    label: Text(test['report_delivery_time']),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade200),
                    avatar: const Icon(Icons.access_time, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${test['price']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTestDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final sampleTypeController = TextEditingController();
    final preparationController = TextEditingController();
    final deliveryTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Test'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Test Name *'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price *'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: sampleTypeController,
                decoration: const InputDecoration(labelText: 'Sample Type (e.g., Blood, Urine)'),
              ),
              TextField(
                controller: preparationController,
                decoration: const InputDecoration(labelText: 'Preparation Required'),
                maxLines: 2,
              ),
              TextField(
                controller: deliveryTimeController,
                decoration: const InputDecoration(labelText: 'Report Delivery Time (e.g., 24 hours)'),
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
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              try {
                await _apiService.post('/api/lab-store/tests', {
                  'name': nameController.text,
                  'description': descController.text,
                  'price': double.parse(priceController.text),
                  'category': categoryController.text,
                  'sample_type': sampleTypeController.text,
                  'preparation_required': preparationController.text,
                  'report_delivery_time': deliveryTimeController.text,
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test added successfully')),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTestDialog(Map<String, dynamic> test) {
    final nameController = TextEditingController(text: test['name']);
    final descController = TextEditingController(text: test['description']);
    final priceController = TextEditingController(text: test['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Test Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.put('/api/lab-store/tests/${test['id']}', {
                  'name': nameController.text,
                  'description': descController.text,
                  'price': double.parse(priceController.text),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test updated successfully')),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(int testId, bool isAvailable) async {
    try {
      await _apiService.put('/api/lab-store/tests/$testId', {
        'is_available': isAvailable,
      });
      if (mounted) {
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

  Future<void> _deleteTest(int testId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: const Text('Are you sure you want to delete this test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.delete('/api/lab-store/tests/$testId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test deleted successfully')),
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
  }
}
