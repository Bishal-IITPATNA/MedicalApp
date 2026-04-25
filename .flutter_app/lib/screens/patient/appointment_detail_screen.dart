import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'buy_medicine_screen.dart';
import 'book_lab_test_screen.dart';
import 'dart:convert';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _prescription;
  List<dynamic> _labTests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptionAndTests();
  }

  Future<void> _loadPrescriptionAndTests() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if appointment already has prescriptions included
      if (widget.appointment['prescriptions'] != null && 
          (widget.appointment['prescriptions'] as List).isNotEmpty) {
        print('Using prescriptions from appointment data');
        _prescription = (widget.appointment['prescriptions'] as List).first;
        print('Found prescription from appointment: $_prescription');
      } else {
        // Fallback to fetching prescriptions separately
        final prescResponse = await _apiService.get('/api/patient/prescriptions');
        print('Prescription response: $prescResponse');
        
        // Handle response - check if data is wrapped or direct
        List<dynamic> prescriptions = [];
        if (prescResponse['prescriptions'] != null) {
          prescriptions = prescResponse['prescriptions'] as List<dynamic>;
        } else if (prescResponse['data']?['prescriptions'] != null) {
          prescriptions = prescResponse['data']['prescriptions'] as List<dynamic>;
        }
        
        print('Total prescriptions: ${prescriptions.length}');
        
        // Find prescription for this appointment
        // First try exact appointment_id match
        for (var p in prescriptions) {
          print('Prescription - id: ${p['id']}, appointment_id: ${p['appointment_id']}, doctor_id: ${p['doctor_id']}');
          if (p['appointment_id'] != null && p['appointment_id'] == widget.appointment['id']) {
            _prescription = p;
            print('Found matching prescription by appointment_id: $_prescription');
            break;
          }
        }
        
        // If no exact match and appointment has doctor_id, find by doctor_id and patient_id
        if (_prescription == null && widget.appointment['doctor_id'] != null) {
          print('No appointment_id match, looking for doctor_id: ${widget.appointment['doctor_id']}, patient_id: ${widget.appointment['patient_id']}');
          for (var p in prescriptions) {
            if (p['doctor_id'] == widget.appointment['doctor_id'] && 
                p['patient_id'] == widget.appointment['patient_id']) {
              _prescription = p;
              print('Found matching prescription by doctor_id and patient_id: $_prescription');
              break;
            }
          }
        }
      }
      
      print('Final prescription: $_prescription');
      
      // Fetch lab test orders
      final labResponse = await _apiService.get('/api/patient/lab-orders');
      print('Lab orders response: $labResponse');
      
      // Handle response - check if data is wrapped or direct
      List<dynamic> allOrders = [];
      if (labResponse['orders'] != null) {
        allOrders = labResponse['orders'] as List<dynamic>;
      } else if (labResponse['data']?['orders'] != null) {
        allOrders = labResponse['data']['orders'] as List<dynamic>;
      }
      
      print('Total lab orders: ${allOrders.length}');
      
      // Filter tests for this appointment
      _labTests = allOrders.where((order) {
        print('Lab order appointment_id: ${order['appointment_id']}, looking for: ${widget.appointment['id']}');
        return order['appointment_id'] == widget.appointment['id'];
      }).toList();
      print('Found ${_labTests.length} matching lab tests');
    } catch (e) {
      print('Error loading prescription: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _hasPrescribedMedicines() {
    if (_prescription == null) return false;
    
    try {
      final medicinesJson = _prescription!['medicines'];
      List<dynamic> medicines = [];
      
      if (medicinesJson is String) {
        medicines = jsonDecode(medicinesJson);
      } else if (medicinesJson is List) {
        medicines = medicinesJson;
      }
      
      return medicines.isNotEmpty;
    } catch (e) {
      print('Error checking prescribed medicines: $e');
      return false;
    }
  }

  void _buyPrescribedMedicines() {
    final status = widget.appointment['status'] ?? 'pending';
    
    if (status != 'completed' && status != 'confirmed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicines can only be purchased for confirmed or completed appointments'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_prescription == null) return;
    
    try {
      final medicinesJson = _prescription!['medicines'];
      List<dynamic> medicines = [];
      
      if (medicinesJson is String) {
        medicines = jsonDecode(medicinesJson);
      } else if (medicinesJson is List) {
        medicines = medicinesJson;
      }
      
      if (medicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No medicines prescribed')),
        );
        return;
      }

      // Navigate to buy medicine screen with appointment ID for prescribed medicines
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuyMedicineScreen(
            appointmentId: widget.appointment['id'],
          ),
        ),
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing medicines prescribed in this appointment'),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _bookLabTest() {
    if (_labTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lab tests prescribed')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookLabTestScreen(),
      ),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search for: ${_labTests.map((t) => t['test_name']).join(', ')}'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.appointment['status'] ?? 'pending';
    final appointmentDate = widget.appointment['appointment_date'];
    final appointmentTime = widget.appointment['appointment_time'];
    final fee = widget.appointment['consultation_fee'] ?? 0.0;
    
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Info Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services, color: Colors.teal.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Doctor Appointment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.confirmation_number, 'Appointment ID', '#${widget.appointment['id'] ?? 'N/A'}'),
                          _buildInfoRow(Icons.calendar_today, 'Date', appointmentDate ?? 'N/A'),
                          _buildInfoRow(Icons.access_time, 'Time', appointmentTime ?? 'N/A'),
                          _buildInfoRow(Icons.currency_rupee, 'Consultation Fee', '₹$fee'),
                          _buildInfoRow(Icons.schedule, 'Created On', _formatDate(widget.appointment['created_at'])),
                          if (widget.appointment['symptoms'] != null)
                            _buildInfoRow(Icons.description, 'Symptoms', widget.appointment['symptoms']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Doctor/Nurse Information Card
                  if (widget.appointment['doctor'] != null || widget.appointment['nurse'] != null) ...[
                    _buildProviderInfoCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Prescription Card - show for confirmed and completed appointments with medicines
                  if (_prescription != null && (status == 'confirmed' || status == 'completed') && _hasPrescribedMedicines()) ...[
                    const Text(
                      'Prescription',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medication, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Prescribed Medicines',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildMedicinesList(),
                            if (_prescription!['instructions'] != null) ...[
                              const Divider(height: 24),
                              Text(
                                'Instructions:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_prescription!['instructions']),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: (status == 'confirmed' || status == 'completed') ? _buyPrescribedMedicines : null,
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Buy Prescribed Medicines'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Lab Tests Card
                  if (_labTests.isNotEmpty) ...[
                    const Text(
                      'Lab Tests',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.science, color: Colors.purple.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Prescribed Lab Tests',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._labTests.map((test) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.purple.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(test['test_name'] ?? 'Lab Test')),
                                ],
                              ),
                            )),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _bookLabTest,
                                icon: const Icon(Icons.book_online),
                                label: const Text('Book Lab Tests'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Show message for pending appointments
                  if (status == 'pending') ...[
                    Card(
                      elevation: 2,
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appointment Pending',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Prescription and lab tests will be available after your appointment is completed.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show message for completed appointments without prescriptions
                  if (_prescription == null && _labTests.isEmpty && status == 'completed') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No prescription or lab tests prescribed',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProviderInfoCard() {
    final doctor = widget.appointment['doctor'];
    final nurse = widget.appointment['nurse'];
    final isDoctor = doctor != null;
    final provider = isDoctor ? doctor : nurse;
    
    if (provider == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDoctor ? Icons.medical_services : Icons.local_hospital,
                  color: Colors.teal.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isDoctor ? 'Doctor Information' : 'Nurse Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildProviderRow(Icons.person, 'Name', provider['name'] ?? 'N/A'),
            if (provider['specialty'] != null)
              _buildProviderRow(Icons.category, 'Specialty', provider['specialty']),
            if (provider['qualification'] != null)
              _buildProviderRow(Icons.school, 'Qualification', provider['qualification']),
            if (provider['experience_years'] != null)
              _buildProviderRow(Icons.work, 'Experience', '${provider['experience_years']} years'),
            if (provider['phone'] != null)
              _buildProviderRow(Icons.phone, 'Phone', provider['phone']),
            if (provider['email'] != null)
              _buildProviderRow(Icons.email, 'Email', provider['email']),
            if (provider['address'] != null)
              _buildProviderRow(Icons.location_on, 'Address', provider['address']),
            if (provider['consultation_fee'] != null)
              _buildProviderRow(Icons.currency_rupee, 'Consultation Fee', '₹${provider['consultation_fee']}'),
            if (provider['rating'] != null && provider['rating'] > 0)
              _buildProviderRow(Icons.star, 'Rating', '${provider['rating']}/5'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProviderRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildMedicinesList() {
    try {
      final medicinesJson = _prescription!['medicines'];
      List<dynamic> medicines = [];
      
      if (medicinesJson is String) {
        medicines = jsonDecode(medicinesJson);
      } else if (medicinesJson is List) {
        medicines = medicinesJson;
      }
      
      if (medicines.isEmpty) {
        return const Text('No medicines prescribed');
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: medicines.map<Widget>((med) {
          final name = med['name'] ?? med['medicine_name'] ?? 'Unknown';
          final dosage = med['dosage'] ?? '';
          final duration = med['duration'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medication, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (dosage.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Dosage: $dosage',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (duration.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Duration: $duration',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Text('Error parsing medicines: $e');
    }
  }
}
