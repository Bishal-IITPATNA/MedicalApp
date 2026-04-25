import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  List<dynamic> _doctors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/doctor/search');
      print('Doctors response: $response');
      if (response['success']) {
        setState(() {
          _doctors = response['data']['doctors'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading doctors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchDoctors() async {
    setState(() => _isLoading = true);
    
    try {
      String query = '?';
      if (_searchController.text.isNotEmpty) {
        query += 'specialty=${_searchController.text}&';
      }
      if (_cityController.text.isNotEmpty) {
        query += 'city=${_cityController.text}&';
      }
      
      final response = await _apiService.get('/api/doctor/search$query');
      print('Search doctors response: $response');
      if (response['success']) {
        setState(() {
          _doctors = response['data']['doctors'] ?? [];
        });
      }
    } catch (e) {
      print('Error searching doctors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
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
        title: const Text('Find Doctor'),
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by specialty',
                    hintText: 'e.g., Cardiologist, Dentist',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g., New York, Mumbai',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _searchDoctors,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        _cityController.clear();
                        _loadDoctors();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No doctors found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = _doctors[index];
                          return _buildDoctorCard(doctor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showDoctorDetails(doctor);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, size: 32, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor['specialty'] ?? 'General',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doctor['qualification'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_city, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${doctor['city'] ?? 'N/A'}, ${doctor['state'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Consultation Fee: ₹${doctor['consultation_fee'] ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  _bookAppointment(doctor);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doctor['name'] ?? 'Doctor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Specialty', doctor['specialty']),
              _buildDetailRow('Qualification', doctor['qualification']),
              _buildDetailRow('Experience', '${doctor['experience_years'] ?? 'N/A'} years'),
              _buildDetailRow('City', doctor['city']),
              _buildDetailRow('State', doctor['state']),
              _buildDetailRow('Address', doctor['address']),
              _buildDetailRow('Consultation Fee', '₹${doctor['consultation_fee']}'),
              const SizedBox(height: 16),
              const Text(
                'Availability:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildAvailabilityInfo(doctor),
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
              _bookAppointment(doctor);
            },
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilityInfo(Map<String, dynamic> doctor) {
    final availableDaysStr = doctor['available_days'];
    final availableFrom = doctor['available_from'];
    final availableTo = doctor['available_to'];
    
    // Try to parse chambers data if available
    List<dynamic>? chambers;
    try {
      if (availableDaysStr != null && availableDaysStr is String && availableDaysStr.startsWith('[')) {
        chambers = json.decode(availableDaysStr);
      }
    } catch (e) {
      // Not JSON, treat as comma-separated days
    }
    
    if (chambers != null && chambers.isNotEmpty) {
      // Show multiple chambers with different slots
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Chambers & Time Slots',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...chambers.asMap().entries.map((entry) {
            final index = entry.key;
            final chamber = entry.value;
            return _buildChamberCard(chamber, index);
          }),
        ],
      );
    } else {
      // Single location availability
      if (availableDaysStr == null || availableDaysStr.isEmpty) {
        return const Text(
          'No availability information',
          style: TextStyle(color: Colors.grey),
        );
      }
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  '$availableFrom - $availableTo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    availableDaysStr,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildChamberCard(Map<String, dynamic> chamber, int index) {
    final days = chamber['available_days'] as List<dynamic>?;
    final fee = chamber['consultation_fee'] ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  chamber['name'] ?? 'Chamber ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹$fee',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${chamber['address']}, ${chamber['city']}, ${chamber['state']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                '${chamber['available_from']} - ${chamber['available_to']}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: (days ?? []).map<Widget>((day) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  day.toString().substring(0, 3),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade900,
                  ),
                ),
              );
            }).toList(),
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
            width: 120,
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

  void _bookAppointment(Map<String, dynamic> doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BookingDialog(doctor: doctor),
      ),
    );
  }
}

class _BookingDialog extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const _BookingDialog({required this.doctor});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final _apiService = ApiService();
  DateTime? selectedDate;
  Map<String, dynamic>? selectedChamber;
  int? selectedChamberIndex;

  List<Map<String, dynamic>> _parseChambers() {
    try {
      final availableDaysStr = widget.doctor['available_days'];
      print('Doctor: ${widget.doctor['name']}');
      print('Available days raw: $availableDaysStr');
      
      if (availableDaysStr != null && availableDaysStr is String && availableDaysStr.startsWith('[')) {
        final chambers = json.decode(availableDaysStr) as List<dynamic>;
        final parsedChambers = chambers.map((c) => c as Map<String, dynamic>).toList();
        print('Parsed chambers count: ${parsedChambers.length}');
        for (int i = 0; i < parsedChambers.length; i++) {
          print('Chamber $i: ${parsedChambers[i]}');
        }
        return parsedChambers;
      }
    } catch (e) {
      print('Error parsing chambers: $e');
    }
    
    // Single chamber format fallback
    final singleChamber = {
      'address': widget.doctor['address'] ?? 'N/A',
      'city': widget.doctor['city'] ?? '',
      'state': widget.doctor['state'] ?? '',
      'available_from': widget.doctor['available_from'],
      'available_to': widget.doctor['available_to'],
      'available_days': widget.doctor['available_days']?.split(',') ?? [],
      'consultation_fee': widget.doctor['consultation_fee'] ?? 0.0,
    };
    print('Using single chamber format: $singleChamber');
    return [singleChamber];
  }

  @override
  Widget build(BuildContext context) {
    final chambers = _parseChambers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(Icons.person, size: 32, color: Colors.teal.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctor['name'] ?? 'Doctor',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor['specialty'] ?? 'General',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Select Date
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: selectedDate != null ? Colors.teal.shade50 : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: selectedDate != null ? Colors.teal : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Choose a date',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null ? Colors.teal.shade900 : Colors.grey,
                        fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Select Time Slot
            const Text(
              'Select Time Slot & Chamber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (selectedDate == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Please select a date first',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...chambers.asMap().entries.map((entry) {
                final index = entry.key;
                final chamber = entry.value;
                final isSelected = selectedChamberIndex == index;
                
                // Auto-select the first chamber if there's only one chamber and no chamber is selected yet
                if (chambers.length == 1 && selectedChamberIndex == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        selectedChamberIndex = 0;
                        selectedChamber = chamber;
                      });
                    }
                  });
                }
                
                return _buildTimeSlotCard(
                  chamber: chamber,
                  index: index,
                  isSelected: isSelected,
                  onTap: () {
                    print('Selected chamber index: $index');
                    print('Chamber data: $chamber');
                    setState(() {
                      selectedChamberIndex = index;
                      selectedChamber = chamber;
                    });
                  },
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedChamber != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedChamber!['name'] ?? 'Selected Chamber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consultation Fee: ₹${selectedChamber!['consultation_fee']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: selectedDate != null && selectedChamber != null
                    ? () => _confirmBooking(
                          selectedDate!,
                          selectedChamber!,
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(DateTime date, Map<String, dynamic> chamber) async {
    // Validate day of week
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final selectedDayName = days[weekday - 1];
    
    final chamberDays = chamber['available_days'] as List<dynamic>?;
    
    // Check if doctor is available on selected day
    if (chamberDays != null && !chamberDays.any((day) => 
        day.toString().toLowerCase() == selectedDayName.toLowerCase())) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Doctor is not available on $selectedDayName at this chamber. Available days: ${chamberDays.join(", ")}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Check if booking is for today and time has passed
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    if (isToday) {
      final availableFrom = chamber['available_from'] ?? '';
      final availableTo = chamber['available_to'] ?? '';
      
      // Parse the availability end time
      TimeOfDay? endTime;
      try {
        if (availableTo.contains('AM') || availableTo.contains('PM')) {
          // Parse 12-hour format
          final timeParts = availableTo.replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
          if (timeParts.length == 2) {
            final timeValue = timeParts[0];
            final period = timeParts[1].toUpperCase();
            final timeComponents = timeValue.split(':');
            
            if (timeComponents.length >= 2) {
              int hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              
              if (period == 'PM' && hour != 12) {
                hour += 12;
              } else if (period == 'AM' && hour == 12) {
                hour = 0;
              }
              
              endTime = TimeOfDay(hour: hour, minute: minute);
            }
          }
        } else {
          // Parse 24-hour format
          final timeComponents = availableTo.split(':');
          if (timeComponents.length >= 2) {
            endTime = TimeOfDay(
              hour: int.parse(timeComponents[0]),
              minute: int.parse(timeComponents[1]),
            );
          }
        }
      } catch (e) {
        print('Error parsing end time: $e');
      }
      
      if (endTime != null) {
        final currentTime = TimeOfDay.fromDateTime(now);
        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        
        if (currentMinutes >= endMinutes) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot book appointment for today. Doctor\'s availability time ($availableFrom - $availableTo) has passed.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        
        // Also check if current time is before availability starts
        TimeOfDay? startTime;
        try {
          if (availableFrom.contains('AM') || availableFrom.contains('PM')) {
            final timeParts = availableFrom.replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
            if (timeParts.length == 2) {
              final timeValue = timeParts[0];
              final period = timeParts[1].toUpperCase();
              final timeComponents = timeValue.split(':');
              
              if (timeComponents.length >= 2) {
                int hour = int.parse(timeComponents[0]);
                final minute = int.parse(timeComponents[1]);
                
                if (period == 'PM' && hour != 12) {
                  hour += 12;
                } else if (period == 'AM' && hour == 12) {
                  hour = 0;
                }
                
                startTime = TimeOfDay(hour: hour, minute: minute);
              }
            }
          } else {
            final timeComponents = availableFrom.split(':');
            if (timeComponents.length >= 2) {
              startTime = TimeOfDay(
                hour: int.parse(timeComponents[0]),
                minute: int.parse(timeComponents[1]),
              );
            }
          }
        } catch (e) {
          print('Error parsing start time: $e');
        }
        
        if (startTime != null) {
          final startMinutes = startTime.hour * 60 + startTime.minute;
          
          if (currentMinutes < startMinutes) {
            if (!mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Doctor is not available yet. Availability starts at $availableFrom.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      }
    }
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Get start time from chamber for appointment_time
      final startTime = chamber['available_from'] ?? '09:00';
      
      // Convert 12-hour format to 24-hour format if needed
      String formattedTime = startTime;
      if (startTime.contains('AM') || startTime.contains('PM')) {
        // Parse 12-hour format and convert to 24-hour
        final timeParts = startTime.replaceAll(RegExp(r'\s+'), ' ').trim().split(' ');
        if (timeParts.length == 2) {
          final timeValue = timeParts[0];
          final period = timeParts[1].toUpperCase();
          final timeComponents = timeValue.split(':');
          
          if (timeComponents.length >= 2) {
            int hour = int.parse(timeComponents[0]);
            final minute = timeComponents[1];
            
            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }
            
            formattedTime = '${hour.toString().padLeft(2, '0')}:$minute';
          }
        }
      }
      
      print('Booking appointment: doctor_id=${widget.doctor['id']}, date=${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}, time=$formattedTime, fee=${chamber['consultation_fee']}');
      
      final response = await _apiService.post('/api/appointments/', {
        'doctor_id': widget.doctor['id'],
        'appointment_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'appointment_time': formattedTime,
        'appointment_type': 'doctor',
        'consultation_fee': chamber['consultation_fee'] ?? 0.0,
        'symptoms': '',
      });
      
      print('Appointment response: $response');
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Check if booking was successful
      if (response['success'] == true) {
        // Close booking dialog
        Navigator.pop(context);
        
        final chamberName = chamber['name'] ?? 'Selected Chamber';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment booked successfully for ${date.day}/${date.month}/${date.year} at $chamberName',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Show error message from backend
        final errorMessage = response['error'] ?? 'Failed to book appointment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildTimeSlotCard({
    required Map<String, dynamic> chamber,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final days = chamber['available_days'] as List<dynamic>?;
    final fee = chamber['consultation_fee'] ?? 0.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chamber['name'] ?? 'Chamber ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹$fee',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: Colors.teal, size: 24),
                  ),
              ],
            ),
            // Always show chamber address details
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${chamber['address'] ?? 'Address not specified'}, ${chamber['city'] ?? 'City not specified'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: isSelected ? Colors.teal : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '${chamber['available_from']} - ${chamber['available_to']}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.teal.shade900 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (days ?? []).map<Widget>((day) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    day.toString().substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.teal.shade900 : Colors.grey.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
