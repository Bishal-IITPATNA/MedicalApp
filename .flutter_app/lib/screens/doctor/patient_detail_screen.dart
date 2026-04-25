import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;
  final int? appointmentId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.appointmentId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic>? _patientData;
  List<dynamic> _prescriptions = [];
  List<dynamic> _labOrders = [];
  List<dynamic> _medicineOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatientHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/patient-history/${widget.patientId}');
      
      if (response['success'] && mounted) {
        final data = response['data'];
        setState(() {
          _patientData = data['patient'];
          _prescriptions = data['prescriptions'] ?? [];
          _labOrders = data['lab_orders'] ?? [];
          _medicineOrders = data['medicine_orders'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patient history: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_patientData?['name'] ?? 'Patient Details'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.person)),
            Tab(text: 'Prescriptions', icon: Icon(Icons.medication)),
            Tab(text: 'Lab Tests', icon: Icon(Icons.science)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildOverviewTab(),
                _buildPrescriptionsTab(),
                _buildLabTestsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPrescribeDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Prescribe'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_patientData == null) {
      return const Center(child: Text('No patient data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(Icons.person, size: 40, color: Colors.teal.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patientData!['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${_patientData!['id']}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.phone, 'Phone', _patientData!['phone'] ?? 'N/A'),
                  _buildInfoRow(Icons.cake, 'DOB', _patientData!['date_of_birth'] ?? 'N/A'),
                  _buildInfoRow(Icons.wc, 'Gender', _patientData!['gender'] ?? 'N/A'),
                  _buildInfoRow(Icons.bloodtype, 'Blood Group', _patientData!['blood_group'] ?? 'N/A'),
                  _buildInfoRow(Icons.location_on, 'Address', _patientData!['address'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Prescriptions',
                  '${_prescriptions.length}',
                  Icons.medication,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Lab Tests',
                  '${_labOrders.length}',
                  Icons.science,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Medicine Orders',
                  '${_medicineOrders.length}',
                  Icons.medical_services,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No prescriptions yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = _prescriptions[index];
        List<dynamic> medicines = [];
        
        try {
          if (prescription['medicines_list'] != null) {
            medicines = prescription['medicines_list'];
          }
        } catch (e) {
          // Ignore parse errors
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      prescription['prescription_date']?.substring(0, 10) ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (prescription['doctor_name'] != null)
                      Text(
                        prescription['doctor_name'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                  ],
                ),
                if (medicines.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Medicines:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...medicines.map((med) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${med['name']} - ${med['dosage']} - ${med['duration']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
                if (prescription['instructions'] != null &&
                    prescription['instructions'].toString().isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prescription['instructions'],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabTestsTab() {
    if (_labOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No lab tests yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _labOrders.length,
      itemBuilder: (context, index) {
        final order = _labOrders[index];
        final items = order['items'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      order['order_date']?.substring(0, 10) ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(order['status'])),
                      ),
                      child: Text(
                        order['status']?.toUpperCase() ?? 'N/A',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (items.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Tests:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final test = item['test'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6),
                          const SizedBox(width: 8),
                          Expanded(child: Text(test?['name'] ?? 'N/A')),
                          Text('₹${item['price']}'),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'recommended':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showPrescribeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 700,
          child: PrescribeSheet(
            patientId: widget.patientId,
            onPrescribed: () {
              _loadPatientHistory();
            },
          ),
        ),
      ),
    );
  }
}

class PrescribeSheet extends StatefulWidget {
  final int patientId;
  final VoidCallback onPrescribed;

  const PrescribeSheet({
    super.key,
    required this.patientId,
    required this.onPrescribed,
  });

  @override
  State<PrescribeSheet> createState() => _PrescribeSheetState();
}

class _PrescribeSheetState extends State<PrescribeSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  // Prescription fields
  final List<Map<String, String>> _medicines = [];
  final _instructionsController = TextEditingController();
  
  // Lab test fields
  final List<int> _selectedTestIds = [];
  List<dynamic> _availableTests = [];
  int? _selectedLabId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableTests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTests() async {
    try {
      final response = await _apiService.get('/api/doctor/lab-tests/available');
      if (response['success'] && mounted) {
        setState(() {
          _availableTests = response['data']['tests'] ?? [];
          if (_availableTests.isNotEmpty) {
            _selectedLabId = _availableTests[0]['lab_id'];
          }
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Prescribe for Patient'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Medicines'),
            Tab(text: 'Lab Tests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMedicinesTab(),
          _buildLabTestsTab(),
        ],
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._medicines.asMap().entries.map((entry) {
                final index = entry.key;
                final medicine = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicine['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _medicines.removeAt(index));
                              },
                            ),
                          ],
                        ),
                        Text('Dosage: ${medicine['dosage']}'),
                        Text('Duration: ${medicine['duration']}'),
                      ],
                    ),
                  ),
                );
              }),
              ElevatedButton.icon(
                onPressed: _addMedicine,
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                  hintText: 'Enter special instructions...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _medicines.isEmpty ? null : _submitPrescription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
              ),
              child: const Text('Submit Prescription'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabTestsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select tests to recommend:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._availableTests.map((test) {
                final isSelected = _selectedTestIds.contains(test['id']);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedTestIds.add(test['id']);
                      } else {
                        _selectedTestIds.remove(test['id']);
                      }
                    });
                  },
                  title: Text(test['name'] ?? ''),
                  subtitle: test['description'] != null && test['description'].toString().isNotEmpty
                      ? Text(test['description'])
                      : null,
                  secondary: const Icon(Icons.science),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTestIds.isEmpty ? null : _submitLabTests,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
              ),
              child: const Text('Recommend Tests'),
            ),
          ),
        ),
      ],
    );
  }

  void _addMedicine() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medicine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage (e.g., 1 tablet twice daily)'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Duration (e.g., 7 days)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _medicines.add({
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'duration': durationController.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPrescription() async {
    try {
      final response = await _apiService.post('/api/prescriptions/', {
        'patient_id': widget.patientId,
        'medicines': _medicines,
        'instructions': _instructionsController.text,
      });

      if (!mounted) return;

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPrescribed();
        Navigator.pop(context);
      } else {
        throw Exception(response['error'] ?? 'Failed to create prescription');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitLabTests() async {
    if (_selectedLabId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lab selected'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final response = await _apiService.post('/api/doctor/lab-tests/recommend', {
        'patient_id': widget.patientId,
        'test_ids': _selectedTestIds,
        'lab_id': _selectedLabId,
        'notes': 'Recommended by doctor',
      });

      if (!mounted) return;

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab tests recommended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPrescribed();
        Navigator.pop(context);
      } else {
        throw Exception(response['error'] ?? 'Failed to recommend tests');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
