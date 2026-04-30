import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/prescription_picker.dart';

class LabTestBookingScreen extends StatefulWidget {
  const LabTestBookingScreen({super.key});

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> labTests = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> selectedTests = <Map<String, dynamic>>[];
  Map<String, dynamic>? selectedLab;
  List<Map<String, dynamic>> labStores = <Map<String, dynamic>>[];
  bool isLoading = true;
  String? error;
  String? searchName;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController _addressController = TextEditingController();

  // Optional prescription attached by the patient.
  String? _prescriptionDataUrl;
  String? _prescriptionFilename;
  
  @override
  void initState() {
    super.initState();
    _loadLabStores();
    _loadLabTests();
  }

  Future<void> _loadLabStores() async {
    try {
      final response = await _apiService.get('/api/patient/lab-stores');
      
      print('Lab Stores API Response: $response'); // Debug print
      print('Lab Stores Response type: ${response.runtimeType}');
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        print('Lab Stores Success: ${response['success']}');
        print('Lab Stores data: ${data}');
        setState(() {
          labStores = data != null && data['labs'] != null 
            ? List<Map<String, dynamic>>.from(data['labs'])
            : <Map<String, dynamic>>[];
        });
      } else {
        print('Lab Stores Error: ${response['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error loading lab stores: $e');
      setState(() {
        labStores = <Map<String, dynamic>>[];
      });
    }
  }

  Future<void> _loadLabTests() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      Map<String, String> queryParams = {};
      if (searchName != null && searchName!.isNotEmpty) {
        queryParams['test_name'] = searchName!;
      }
      if (selectedLab != null) {
        queryParams['lab_id'] = selectedLab!['id'].toString();
      }

      String queryString = queryParams.isEmpty ? '' : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      
      final response = await _apiService.get('/api/patient/lab-tests/search$queryString');
      
      print('Lab Tests API Response: $response'); // Debug print
      print('Response type: ${response.runtimeType}');
      if (response['success'] == true) {
        print('Success: ${response['success']}');
        print('Tests data: ${response['tests']}');
      } else {
        print('Error response: ${response['error'] ?? 'Unknown error'}');
      }
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        setState(() {
          labTests = data != null && data['tests'] != null 
            ? List<Map<String, dynamic>>.from(data['tests'])
            : <Map<String, dynamic>>[];
          isLoading = false;
        });
      } else {
        final errorMsg = response['error'] ?? 'Failed to load lab tests';
        print('Lab Tests Error: $errorMsg');
        setState(() {
          error = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
        labTests = <Map<String, dynamic>>[];
      });
    }
  }

  void _performSearch() {
    setState(() {
      searchName = _searchController.text.trim();
    });
    _loadLabTests();
  }

  void _toggleTestSelection(Map<String, dynamic> test) {
    setState(() {
      bool isSelected = selectedTests.any((t) => t['id'] == test['id']);
      
      if (isSelected) {
        selectedTests.removeWhere((t) => t['id'] == test['id']);
      } else {
        selectedTests.add(test);
      }
    });
  }

  double _calculateTotal() {
    return selectedTests.fold(0.0, (sum, test) {
      final price = test['price'];
      if (price is num) {
        return sum + price.toDouble();
      }
      return sum;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _bookLabTests() async {
    print('Starting lab test booking...'); // Debug
    print('Selected tests: $selectedTests'); // Debug
    print('Selected date: $selectedDate'); // Debug
    print('Selected time: $selectedTime'); // Debug
    
    if (selectedTests.isEmpty) {
      print('Error: No tests selected'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one test')),
      );
      return;
    }

    if (selectedDate == null) {
      print('Error: selectedDate is null'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select test date')),
      );
      return;
    }

    print('Booking lab tests with date: $selectedDate'); // Debug

    // Group tests by lab
    Map<int, List<Map<String, dynamic>>> testsByLab = {};
    for (var test in selectedTests) {
      print('Processing test: $test'); // Debug
      
      final labInfo = test['lab_info'] as Map<String, dynamic>?;
      if (labInfo == null) {
        print('Error: lab_info is null for test: $test');
        throw Exception('Invalid test data: lab information missing for test ${test['name'] ?? 'unknown'}');
      }
      
      final labIdValue = labInfo['id'];
      if (labIdValue == null) {
        print('Error: lab_info.id is null for test: $test');
        throw Exception('Invalid test data: lab ID missing for test ${test['name'] ?? 'unknown'}');
      }
      
      int labId;
      try {
        labId = labIdValue as int;
      } catch (e) {
        print('Error: lab_info.id is not an int: $labIdValue');
        throw Exception('Invalid test data: lab ID is not a number for test ${test['name'] ?? 'unknown'}');
      }
      
      if (!testsByLab.containsKey(labId)) {
        testsByLab[labId] = [];
      }
      testsByLab[labId]!.add(test);
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<int> orderIds = [];
      
      // Book tests for each lab separately
      for (var entry in testsByLab.entries) {
        int labId = entry.key;
        List<Map<String, dynamic>> testsForLab = entry.value;
        
        print('Processing ${testsForLab.length} tests for lab $labId'); // Debug
        
        // Build test_ids with comprehensive null checking
        List<int> testIds = [];
        for (var test in testsForLab) {
          final testId = test['id'];
          if (testId == null) {
            print('Warning: test ID is null for test: ${test['name'] ?? 'unknown'}');
            continue; // Skip this test
          }
          try {
            testIds.add(testId as int);
          } catch (e) {
            print('Warning: test ID is not an int: $testId for test: ${test['name'] ?? 'unknown'}');
            continue; // Skip this test
          }
        }
        
        if (testIds.isEmpty) {
          throw Exception('No valid test IDs found for lab $labId');
        }
        
        Map<String, dynamic> bookingData = {
          'lab_id': labId,
          'test_ids': testIds,
          'test_date': '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
        };

        if (selectedTime != null) {
          try {
            bookingData['test_time'] = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error formatting time: $e');
            // Continue without time if there's an error
          }
        }

        // Add notes if any
        if (_addressController.text.trim().isNotEmpty) {
          bookingData['notes'] = _addressController.text.trim();
        }

        // Attach prescription if patient uploaded one
        if (_prescriptionDataUrl != null) {
          bookingData['prescription_image'] = _prescriptionDataUrl;
          bookingData['prescription_filename'] = _prescriptionFilename;
        }

        print('Booking lab tests for lab $labId with data: $bookingData'); // Debug
        final response = await _apiService.post('/api/patient/lab-tests/book', bookingData);
        print('Booking response: $response'); // Debug
        print('Response success: ${response['success']}'); // Debug
        
        if (response['success'] == true) {
          // Handle API service wrapper - response['data'] contains the actual backend response
          final apiData = response['data'] as Map<String, dynamic>?;
          print('API data from backend: $apiData'); // Debug
          
          if (apiData != null) {
            // Backend returns order_id directly in the response, no nested 'success' field needed
            final orderId = apiData['order_id'];
            print('Extracted order ID: $orderId'); // Debug
            if (orderId != null) {
              try {
                orderIds.add(orderId as int);
                print('Added order ID to list: $orderId');
              } catch (e) {
                print('Error converting order ID to int: $e');
              }
            } else {
              print('Warning: order_id is null in response');
            }
          } else {
            print('Error: apiData is null');
            throw Exception('Invalid response format from server');
          }
        } else {
          throw Exception(response['error'] ?? 'Failed to book tests');
        }
      }

      Navigator.pop(context); // Close loading dialog

      print('Preparing success dialog...'); // Debug
      print('Order IDs: $orderIds'); // Debug
      print('Selected date for dialog: $selectedDate'); // Debug
      print('Selected time for dialog: $selectedTime'); // Debug

      // Show success dialog
      try {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('Booking Successful'),
              ],
            ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lab tests booked successfully!'),
              const SizedBox(height: 8),
              if (orderIds.isNotEmpty) ...[
                Text('Order IDs: ${orderIds.join(", ")}'),
                const SizedBox(height: 8),
              ],
              if (selectedDate != null) ...[
                Text('Test Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                const SizedBox(height: 8),
              ],
              if (selectedTime != null) ...[
                Text('Time: ${selectedTime!.format(context)}'),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You will receive an OTP notification for sample collection confirmation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      } catch (dialogError) {
        print('Error showing success dialog: $dialogError');
        // Fallback: show simple snackbar if dialog fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lab tests booked successfully! Order IDs: ${orderIds.join(", ")}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Clear selections
      setState(() {
        selectedTests.clear();
        selectedDate = null;
        selectedTime = null;
        _addressController.clear();
        _prescriptionDataUrl = null;
        _prescriptionFilename = null;
      });

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      print('Lab booking error: $e'); // Debug print
      
      String errorMessage = 'Error booking lab tests: $e';
      
      // Provide more specific error messages for common issues
      if (e.toString().contains('No access token')) {
        errorMessage = 'Please log in again to book lab tests';
      } else if (e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expired. Please log in again';
      } else if (e.toString().contains('Connection error')) {
        errorMessage = 'Network connection error. Please check your internet connection';
      } else if (e.toString().contains('Invalid test data')) {
        errorMessage = 'Invalid test selection. Please try again';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _bookLabTests(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Lab Tests'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search lab tests...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchName = null;
                        });
                        _loadLabTests();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: labStores.length,
                    itemBuilder: (context, index) {
                      final lab = labStores[index];
                      final isSelected = selectedLab != null && selectedLab!['id'] == lab['id'];
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(lab['name']),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedLab = selected ? lab : null;
                            });
                            _loadLabTests();
                          },
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue.shade700,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (selectedTests.isNotEmpty)
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedTests.length} tests selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'Total: ₹${_calculateTotal().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadLabTests,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : labTests.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No lab tests found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                SizedBox(height: 8),
                                Text('Try searching or selecting a different lab', 
                                     style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLabTests,
                            child: ListView.builder(
                              itemCount: labTests.length,
                              itemBuilder: (context, index) {
                                final test = labTests[index];
                                final labInfo = test['lab_info'] as Map<String, dynamic>?;
                                final isSelected = selectedTests.any((t) => t['id'] == test['id']);
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected ? Colors.green.shade100 : Colors.blue.shade100,
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.science,
                                        color: isSelected ? Colors.green.shade700 : Colors.blue.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      test['name'] ?? 'N/A',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (test['description'] != null)
                                          Text(
                                            test['description'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (test['category'] != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  test['category'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (test['sample_type'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  test['sample_type'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.orange.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.local_hospital, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                labInfo != null 
                                                  ? '${labInfo['name'] ?? 'Lab'} - ${labInfo['address'] ?? 'Address'}, ${labInfo['city'] ?? 'City'}'
                                                  : 'Lab information not available',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (test['report_delivery_time'] != null)
                                              Row(
                                                children: [
                                                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Report: ${test['report_delivery_time']}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                            Text(
                                              '₹${test['price'] ?? 0}',
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
                                    isThreeLine: true,
                                    onTap: () => _toggleTestSelection(test),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
          if (selectedTests.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(selectedDate == null 
                              ? 'Select Date' 
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime == null 
                              ? 'Select Time' 
                              : selectedTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Any special instructions for the lab test',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  PrescriptionPicker(
                    key: const ValueKey('rx-lab-picker'),
                    onChanged: (dataUrl, filename) {
                      setState(() {
                        _prescriptionDataUrl = dataUrl;
                        _prescriptionFilename = filename;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookLabTests,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(0, 50),
                      ),
                      child: Text(
                        'Book Tests - ₹${_calculateTotal().toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}