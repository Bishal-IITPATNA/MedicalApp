import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class TimeSlot {
  final TextEditingController availableFromController;
  final TextEditingController availableToController;
  final Set<String> availableDays;

  TimeSlot()
      : availableFromController = TextEditingController(),
        availableToController = TextEditingController(),
        availableDays = {};

  Map<String, dynamic> toJson() {
    return {
      'available_from': availableFromController.text,
      'available_to': availableToController.text,
      'available_days': availableDays.toList(),
    };
  }

  void dispose() {
    availableFromController.dispose();
    availableToController.dispose();
  }
}

class NurseProfileCompletion extends StatefulWidget {
  const NurseProfileCompletion({super.key});

  @override
  State<NurseProfileCompletion> createState() => _NurseProfileCompletionState();
}

class _NurseProfileCompletionState extends State<NurseProfileCompletion> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _pageController = PageController();
  
  // Controllers
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  // Multiple time slots
  final List<TimeSlot> _timeSlots = [TimeSlot()];
  int _currentTimeSlotIndex = 0;
  
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _qualificationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    for (var timeSlot in _timeSlots) {
      timeSlot.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(TimeSlot());
      _currentTimeSlotIndex = _timeSlots.length - 1;
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots.length > 1) {
      setState(() {
        _timeSlots[index].dispose();
        _timeSlots.removeAt(index);
        if (_currentTimeSlotIndex >= _timeSlots.length) {
          _currentTimeSlotIndex = _timeSlots.length - 1;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one time slot is required')),
      );
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate all time slots
    for (var i = 0; i < _timeSlots.length; i++) {
      final timeSlot = _timeSlots[i];
      if (timeSlot.availableFromController.text.isEmpty ||
          timeSlot.availableToController.text.isEmpty ||
          timeSlot.availableDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all fields for Time Slot ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Serialize time slots to JSON
      final timeSlotsJson = jsonEncode(_timeSlots.map((slot) => slot.toJson()).toList());

      final response = await _apiService.put('/api/nurse/profile', {
        'qualification': _qualificationController.text,
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'consultation_fee': double.tryParse(_feeController.text) ?? 0.0,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'time_slots': timeSlotsJson,
      });

      if (mounted) {
        if (response['success']) {
          Navigator.pushReplacementNamed(context, '/nurse-dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error'] ?? 'Failed to save profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _saveProfile();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[200],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildProfessionalInfoPage(),
                  _buildLocationPage(),
                  _buildAvailabilityPage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Information', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Step 1 of 3', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextFormField(
            controller: _qualificationController,
            decoration: const InputDecoration(labelText: 'Qualification', hintText: 'e.g., B.Sc Nursing, GNM', prefixIcon: Icon(Icons.school), border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter your qualification' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _experienceController,
            decoration: const InputDecoration(labelText: 'Years of Experience', prefixIcon: Icon(Icons.work_history), border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter years of experience' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _feeController,
            decoration: const InputDecoration(labelText: 'Service Fee (₹)', prefixIcon: Icon(Icons.currency_rupee), border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter service fee' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Step 2 of 3', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home), border: OutlineInputBorder()),
            maxLines: 2,
            validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city), border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter city' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stateController,
            decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map), border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter state' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pincodeController,
            decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin_drop), border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter pincode';
              if (value.length != 6) return 'Pincode must be 6 digits';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Availability', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addTimeSlot,
                icon: const Icon(Icons.add),
                label: const Text('Add Time Slot'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Step 3 of 3', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 16),
          // Time Slot Navigation Chips
          if (_timeSlots.length > 1)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_timeSlots.length, (index) {
                return ChoiceChip(
                  label: Text('Time Slot ${index + 1}'),
                  selected: _currentTimeSlotIndex == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentTimeSlotIndex = index;
                      });
                    }
                  },
                );
              }),
            ),
          const SizedBox(height: 24),
          // Current Time Slot Form
          _buildTimeSlotForm(_timeSlots[_currentTimeSlotIndex], _currentTimeSlotIndex),
        ],
      ),
    );
  }

  Widget _buildTimeSlotForm(TimeSlot timeSlot, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Time Slot ${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_timeSlots.length > 1)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeTimeSlot(index),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Available Days', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final isSelected = timeSlot.availableDays.contains(day);
            return FilterChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    timeSlot.availableDays.add(day);
                  } else {
                    timeSlot.availableDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: timeSlot.availableFromController,
                decoration: const InputDecoration(labelText: 'Available From', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                readOnly: true,
                onTap: () => _selectTime(timeSlot.availableFromController),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: timeSlot.availableToController,
                decoration: const InputDecoration(labelText: 'Available To', prefixIcon: Icon(Icons.access_time), border: OutlineInputBorder()),
                readOnly: true,
                onTap: () => _selectTime(timeSlot.availableToController),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)).let((shadow) => BoxDecoration(color: Colors.white, boxShadow: [shadow])),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(child: OutlinedButton(onPressed: _previousPage, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Previous'))),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_currentPage < 2 ? 'Next' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }
}

extension on BoxShadow {
  BoxDecoration let(BoxDecoration Function(BoxShadow) fn) => fn(this);
}
