import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BookLabTestScreen extends StatefulWidget {
  const BookLabTestScreen({super.key});

  @override
  State<BookLabTestScreen> createState() => _BookLabTestScreenState();
}

class _BookLabTestScreenState extends State<BookLabTestScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  List<dynamic> _labTests = [];
  final Map<int, bool> _selectedTests = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLabTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabTests() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/lab-store/search');
      print('Lab tests response: $response');
      if (response['success']) {
        setState(() {
          _labTests = response['data']['tests'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading lab tests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lab tests: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLabTests() async {
    if (_searchController.text.isEmpty) {
      _loadLabTests();
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/lab-store/search?name=${_searchController.text}');
      print('Search lab tests response: $response');
      if (response['success']) {
        setState(() {
          _labTests = response['data']['tests'] ?? [];
        });
      }
    } catch (e) {
      print('Error searching lab tests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTest(int testId) {
    setState(() {
      if (_selectedTests.containsKey(testId)) {
        _selectedTests.remove(testId);
      } else {
        _selectedTests[testId] = true;
      }
    });
  }

  void _viewSelectedTests() {
    final selectedTests = _labTests.where((t) => _selectedTests.containsKey(t['id'])).toList();
    
    if (selectedTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one test')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selected Tests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: selectedTests.length,
                  itemBuilder: (context, index) {
                    final test = selectedTests[index];
                    return ListTile(
                      leading: const Icon(Icons.science, color: Colors.purple),
                      title: Text(test['name'] ?? 'Unknown'),
                      subtitle: Text(test['description'] ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${test['price']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedTests.remove(test['id']);
                              });
                              Navigator.pop(context);
                              if (_selectedTests.isNotEmpty) {
                                _viewSelectedTests();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${_calculateTotal(selectedTests)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _bookTests();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Book Tests'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal(List<dynamic> tests) {
    double total = 0;
    for (var test in tests) {
      final price = double.tryParse(test['price']?.toString() ?? '0') ?? 0;
      total += price;
    }
    return total;
  }

  void _bookTests() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Lab Tests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select appointment date and time:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Preferred Date',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Preferred Time',
                hintText: 'HH:MM',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedTests.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lab tests booked successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Lab Test'),
        actions: [
          if (_selectedTests.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.playlist_add_check),
                  onPressed: _viewSelectedTests,
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
                    child: Text(
                      '${_selectedTests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search test',
                      hintText: 'e.g., Blood Test, X-Ray',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchLabTests(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searchLabTests,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _labTests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.science, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No lab tests found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _labTests.length,
                        itemBuilder: (context, index) {
                          final test = _labTests[index];
                          final isSelected = _selectedTests.containsKey(test['id']);
                          return _buildLabTestCard(test, isSelected);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _selectedTests.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _viewSelectedTests,
              icon: const Icon(Icons.playlist_add_check),
              label: Text('View Selected (${_selectedTests.length})'),
            )
          : null,
    );
  }

  Widget _buildLabTestCard(Map<String, dynamic> test, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.purple.shade50 : null,
      child: InkWell(
        onTap: () => _showTestDetails(test),
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.science, color: Colors.purple.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          test['category'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) => _toggleTest(test['id']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (test['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    test['description'],
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price: ₹${test['price']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (isSelected)
                    Chip(
                      label: const Text('Selected'),
                      backgroundColor: Colors.purple.shade100,
                      labelStyle: TextStyle(color: Colors.purple.shade700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestDetails(Map<String, dynamic> test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(test['name'] ?? 'Test Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', test['category']),
              _buildDetailRow('Price', '₹${test['price']}'),
              _buildDetailRow('Description', test['description']),
              _buildDetailRow('Preparation', test['preparation_instructions']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleTest(test['id']);
            },
            child: Text(_selectedTests.containsKey(test['id']) ? 'Remove' : 'Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
