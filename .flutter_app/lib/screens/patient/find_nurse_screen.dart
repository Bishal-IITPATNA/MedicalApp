import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FindNurseScreen extends StatefulWidget {
  const FindNurseScreen({super.key});

  @override
  State<FindNurseScreen> createState() => _FindNurseScreenState();
}

class _FindNurseScreenState extends State<FindNurseScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  List<dynamic> _nurses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNurses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadNurses() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/nurse/search');
      print('Nurses response: $response');
      if (response['success']) {
        setState(() {
          _nurses = response['data']['nurses'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading nurses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading nurses: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchNurses() async {
    setState(() => _isLoading = true);
    
    try {
      String query = '?';
      if (_searchController.text.isNotEmpty) {
        query += 'qualification=${_searchController.text}&';
      }
      if (_cityController.text.isNotEmpty) {
        query += 'city=${_cityController.text}&';
      }
      
      final response = await _apiService.get('/api/nurse/search$query');
      print('Search nurses response: $response');
      if (response['success']) {
        setState(() {
          _nurses = response['data']['nurses'] ?? [];
        });
      }
    } catch (e) {
      print('Error searching nurses: $e');
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
        title: const Text('Find Nurse'),
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
                    labelText: 'Search by qualification',
                    hintText: 'e.g., RN, BSN',
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
                        onPressed: _searchNurses,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        _cityController.clear();
                        _loadNurses();
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
                : _nurses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No nurses found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _nurses.length,
                        itemBuilder: (context, index) {
                          final nurse = _nurses[index];
                          return _buildNurseCard(nurse);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNurseCard(Map<String, dynamic> nurse) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showNurseDetails(nurse);
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
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.local_hospital, size: 32, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nurse['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nurse['qualification'] ?? 'Nurse',
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
                  Icon(Icons.location_city, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${nurse['city'] ?? 'N/A'}, ${nurse['state'] ?? ''}',
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
                    'Consultation Fee: ₹${nurse['consultation_fee'] ?? 'N/A'}',
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
                  _bookAppointment(nurse);
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

  void _showNurseDetails(Map<String, dynamic> nurse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nurse['name'] ?? 'Nurse Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Qualification', nurse['qualification']),
              _buildDetailRow('City', nurse['city']),
              _buildDetailRow('State', nurse['state']),
              _buildDetailRow('Phone', nurse['phone']),
              _buildDetailRow('Consultation Fee', '₹${nurse['consultation_fee']}'),
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
              _bookAppointment(nurse);
            },
            child: const Text('Book Appointment'),
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

  void _bookAppointment(Map<String, dynamic> nurse) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookNurseAppointmentScreen(nurse: nurse),
      ),
    );
  }
}

class BookNurseAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const BookNurseAppointmentScreen({super.key, required this.nurse});

  @override
  State<BookNurseAppointmentScreen> createState() => _BookNurseAppointmentScreenState();
}

class _BookNurseAppointmentScreenState extends State<BookNurseAppointmentScreen> {
  final _apiService = ApiService();
  final _symptomsController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _durationType = 'single'; // 'single' or 'multiple'
  int _durationDays = 1;
  
  List<Map<String, dynamic>> _availability = [];
  bool _isLoadingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoadingAvailability = true);
    
    try {
      // Check if nurse data already has availability
      if (widget.nurse['available_days'] != null) {
        final availableDays = widget.nurse['available_days'];
        
        if (availableDays is List && availableDays.isNotEmpty) {
          // Parse the available_days field
          Map<String, List<String>> daySlots = {};
          
          for (var slot in availableDays) {
            final days = slot['available_days'] as List?;
            final timeSlot = '${slot['available_from']} - ${slot['available_to']}';
            
            if (days != null) {
              for (var day in days) {
                if (daySlots.containsKey(day)) {
                  daySlots[day]!.add(timeSlot);
                } else {
                  daySlots[day] = [timeSlot];
                }
              }
            }
          }
          
          // Create availability list
          List<Map<String, dynamic>> availability = [];
          for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
            availability.add({
              'day': day,
              'available': daySlots.containsKey(day),
              'slots': daySlots[day] ?? [],
            });
          }
          
          setState(() {
            _availability = availability;
          });
        } else {
          _setDefaultAvailability();
        }
      } else {
        _setDefaultAvailability();
      }
    } catch (e) {
      print('Error loading availability: $e');
      _setDefaultAvailability();
    } finally {
      setState(() => _isLoadingAvailability = false);
    }
  }
  
  void _setDefaultAvailability() {
    setState(() {
      _availability = [
        {'day': 'Monday', 'available': true, 'slots': ['09:00 AM - 12:00 PM', '02:00 PM - 05:00 PM']},
        {'day': 'Tuesday', 'available': true, 'slots': ['09:00 AM - 12:00 PM', '02:00 PM - 05:00 PM']},
        {'day': 'Wednesday', 'available': true, 'slots': ['09:00 AM - 12:00 PM', '02:00 PM - 05:00 PM']},
        {'day': 'Thursday', 'available': true, 'slots': ['09:00 AM - 12:00 PM', '02:00 PM - 05:00 PM']},
        {'day': 'Friday', 'available': true, 'slots': ['09:00 AM - 12:00 PM', '02:00 PM - 05:00 PM']},
        {'day': 'Saturday', 'available': false, 'slots': []},
        {'day': 'Sunday', 'available': false, 'slots': []},
      ];
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      // Check if the selected day is available
      final dayOfWeek = _getDayOfWeek(picked.weekday);
      final dayAvailability = _availability.firstWhere(
        (slot) => slot['day'] == dayOfWeek,
        orElse: () => {'day': dayOfWeek, 'available': false},
      );
      
      if (dayAvailability['available'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nurse is not available on $dayOfWeek. Please select another date.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      setState(() => _selectedDate = picked);
    }
  }
  
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    // Validate nurse availability for selected date
    final dayOfWeek = _getDayOfWeek(_selectedDate!.weekday);
    final dayAvailability = _availability.firstWhere(
      (slot) => slot['day'] == dayOfWeek,
      orElse: () => {'day': dayOfWeek, 'available': false},
    );
    
    if (dayAvailability['available'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nurse is not available on $dayOfWeek. Please select another date.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Validate time is within available time slots
    final selectedTimeMinutes = _selectedTime!.hour * 60 + _selectedTime!.minute;
    final availableSlots = dayAvailability['slots'] as List? ?? [];
    
    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No time slots available for $dayOfWeek. Please select another date.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    bool isTimeValid = false;
    String availableSlotsText = '';
    
    for (var slot in availableSlots) {
      final slotStr = slot.toString();
      availableSlotsText += (availableSlotsText.isEmpty ? '' : ', ') + slotStr;
      
      // Parse slot like "09:00 AM - 12:00 PM"
      final parts = slotStr.split(' - ');
      if (parts.length == 2) {
        final startTime = _parseTime(parts[0].trim());
        final endTime = _parseTime(parts[1].trim());
        
        if (startTime != null && endTime != null) {
          if (selectedTimeMinutes >= startTime && selectedTimeMinutes <= endTime) {
            isTimeValid = true;
            break;
          }
        }
      }
    }
    
    if (!isTimeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected time is not within available slots.\nAvailable times on $dayOfWeek: $availableSlotsText',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // For multiple days booking, check if all days are available
    if (_durationType == 'multiple') {
      for (int i = 0; i < _durationDays; i++) {
        final checkDate = _selectedDate!.add(Duration(days: i));
        final checkDayOfWeek = _getDayOfWeek(checkDate.weekday);
        final checkAvailability = _availability.firstWhere(
          (slot) => slot['day'] == checkDayOfWeek,
          orElse: () => {'day': checkDayOfWeek, 'available': false},
        );
        
        if (checkAvailability['available'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nurse is not available on $checkDayOfWeek (day ${i + 1}). Please adjust the booking dates.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        
        // Check time availability for each day
        final checkSlots = checkAvailability['slots'] as List? ?? [];
        if (checkSlots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No time slots available on $checkDayOfWeek (day ${i + 1}). Please adjust the booking.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Format time properly for API (HH:MM without seconds)
      final formattedTime = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      final formattedDate = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      
      print('Booking nurse appointment - Date: $formattedDate, Time: $formattedTime');
      
      final response = await _apiService.post('/api/appointments/', {
        'nurse_id': widget.nurse['id'],
        'appointment_date': formattedDate,
        'appointment_time': formattedTime,
        'appointment_type': 'nurse',
        'symptoms': _symptomsController.text,
        'duration_days': _durationType == 'multiple' ? _durationDays : 1,
      });
      
      print('Booking response: $response');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _durationType == 'multiple'
                  ? 'Appointment booked for $_durationDays days!'
                  : 'Appointment booked successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to nurse list
      } else {
        final errorMsg = response['error'] ?? response['message'] ?? 'Failed to book appointment';
        print('Booking failed: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error booking appointment: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Parse time string like "09:00 AM" or "02:00 PM" to minutes since midnight
  int? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1].toUpperCase() == 'PM';
      
      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }
      
      return hour * 60 + minute;
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Nurse Appointment'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nurse Info Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.local_hospital, size: 35, color: Colors.purple.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nurse['name'] ?? 'Nurse',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.nurse['qualification'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.nurse['consultation_fee']}/day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
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

            // Availability Section
            const Text(
              'Availability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _isLoadingAvailability
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _availability.map((slot) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  slot['available'] == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: slot['available'] == true
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    slot['day'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (slot['slots'] != null && slot['slots'].isNotEmpty)
                                  Text(
                                    (slot['slots'] as List).join(', '),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),

            // Duration Type Selection
            const Text(
              'Booking Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Single Day'),
                    subtitle: const Text('Book for one day only'),
                    value: 'single',
                    groupValue: _durationType,
                    onChanged: (value) {
                      setState(() {
                        _durationType = value!;
                        _durationDays = 1;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Multiple Days'),
                    subtitle: const Text('Book for continuous care'),
                    value: 'multiple',
                    groupValue: _durationType,
                    onChanged: (value) {
                      setState(() => _durationType = value!);
                    },
                  ),
                ],
              ),
            ),
            
            if (_durationType == 'multiple') ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Number of Days',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _durationDays > 1
                                ? () => setState(() => _durationDays--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '$_durationDays days',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _durationDays < 30
                                ? () => setState(() => _durationDays++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${(widget.nurse['consultation_fee'] ?? 0) * _durationDays}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Appointment Details
            const Text(
              'Appointment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Date Selection
            ListTile(
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: Icon(Icons.calendar_today, color: Colors.purple.shade700),
              title: Text(
                _selectedDate == null
                    ? 'Select Start Date'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            
            // Time Selection
            ListTile(
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: Icon(Icons.access_time, color: Colors.purple.shade700),
              title: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),

            // Symptoms/Notes
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Patient Condition/Notes',
                hintText: 'Describe the patient\'s condition and care requirements...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _durationType == 'multiple'
                      ? 'Book for $_durationDays Days'
                      : 'Book Appointment',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
