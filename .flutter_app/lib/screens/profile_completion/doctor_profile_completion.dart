import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class Chamber {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final TextEditingController feeController;
  final TextEditingController availableFromController;
  final TextEditingController availableToController;
  final Set<String> availableDays;

  Chamber()
      : addressController = TextEditingController(),
        cityController = TextEditingController(),
        stateController = TextEditingController(),
        pincodeController = TextEditingController(),
        feeController = TextEditingController(),
        availableFromController = TextEditingController(),
        availableToController = TextEditingController(),
        availableDays = {};

  Map<String, dynamic> toJson() {
    return {
      'address': addressController.text,
      'city': cityController.text,
      'state': stateController.text,
      'pincode': pincodeController.text,
      'consultation_fee': double.tryParse(feeController.text) ?? 0.0,
      'available_from': availableFromController.text,
      'available_to': availableToController.text,
      'available_days': availableDays.toList(),
    };
  }

  void dispose() {
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    feeController.dispose();
    availableFromController.dispose();
    availableToController.dispose();
  }
}

class DoctorProfileCompletion extends StatefulWidget {
  const DoctorProfileCompletion({super.key});

  @override
  State<DoctorProfileCompletion> createState() => _DoctorProfileCompletionState();
}

class _DoctorProfileCompletionState extends State<DoctorProfileCompletion> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _pageController = PageController();
  
  // Controllers for professional info
  final _specialtyController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  
  // List of chambers
  final List<Chamber> _chambers = [Chamber()];
  int _currentChamberIndex = 0;
  
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _specialtyController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    for (var chamber in _chambers) {
      chamber.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _addChamber() {
    setState(() {
      _chambers.add(Chamber());
      _currentChamberIndex = _chambers.length - 1;
    });
  }

  void _removeChamber(int index) {
    if (_chambers.length > 1) {
      setState(() {
        _chambers[index].dispose();
        _chambers.removeAt(index);
        if (_currentChamberIndex >= _chambers.length) {
          _currentChamberIndex = _chambers.length - 1;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one chamber is required')),
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
    
    // Validate all chambers
    for (var i = 0; i < _chambers.length; i++) {
      final chamber = _chambers[i];
      if (chamber.addressController.text.isEmpty ||
          chamber.cityController.text.isEmpty ||
          chamber.stateController.text.isEmpty ||
          chamber.pincodeController.text.isEmpty ||
          chamber.feeController.text.isEmpty ||
          chamber.availableFromController.text.isEmpty ||
          chamber.availableToController.text.isEmpty ||
          chamber.availableDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all fields for Chamber ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Serialize chambers to JSON
      final chambersJson = jsonEncode(_chambers.map((chamber) => chamber.toJson()).toList());

      final response = await _apiService.put('/api/doctor/profile', {
        'specialty': _specialtyController.text,
        'qualification': _qualificationController.text,
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'chambers': chambersJson,
      });

      if (mounted) {
        if (response['success']) {
          Navigator.pushReplacementNamed(context, '/doctor-dashboard');
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
    if (_currentPage < 1) {
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
              value: (_currentPage + 1) / 2,
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
                  _buildChambersPage(),
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
          Text(
            'Professional Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step 1 of 2',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _specialtyController,
            decoration: const InputDecoration(
              labelText: 'Specialty',
              hintText: 'e.g., Cardiologist, Dermatologist',
              prefixIcon: Icon(Icons.medical_services),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your specialty';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _qualificationController,
            decoration: const InputDecoration(
              labelText: 'Qualification',
              hintText: 'e.g., MBBS, MD',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your qualification';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _experienceController,
            decoration: const InputDecoration(
              labelText: 'Years of Experience',
              prefixIcon: Icon(Icons.work_history),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter years of experience';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChambersPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chamber Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addChamber,
                icon: const Icon(Icons.add),
                label: const Text('Add Chamber'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 of 2',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Chamber Navigation Chips
          if (_chambers.length > 1)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_chambers.length, (index) {
                return ChoiceChip(
                  label: Text('Chamber ${index + 1}'),
                  selected: _currentChamberIndex == index,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _currentChamberIndex = index;
                      });
                    }
                  },
                );
              }),
            ),
          const SizedBox(height: 24),
          // Current Chamber Form
          _buildChamberForm(_chambers[_currentChamberIndex], _currentChamberIndex),
        ],
      ),
    );
  }

  Widget _buildChamberForm(Chamber chamber, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chamber ${index + 1}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_chambers.length > 1)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeChamber(index),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: chamber.addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'Street, Building, Landmark',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: chamber.cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: chamber.stateController,
          decoration: const InputDecoration(
            labelText: 'State',
            prefixIcon: Icon(Icons.map),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: chamber.pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            prefixIcon: Icon(Icons.pin_drop),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: chamber.feeController,
          decoration: const InputDecoration(
            labelText: 'Consultation Fee (₹)',
            prefixIcon: Icon(Icons.currency_rupee),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        Text(
          'Available Days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays.map((day) {
            final isSelected = chamber.availableDays.contains(day);
            return FilterChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    chamber.availableDays.add(day);
                  } else {
                    chamber.availableDays.remove(day);
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
                controller: chamber.availableFromController,
                decoration: const InputDecoration(
                  labelText: 'Available From',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectTime(chamber.availableFromController),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: chamber.availableToController,
                decoration: const InputDecoration(
                  labelText: 'Available To',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectTime(chamber.availableToController),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentPage < 1 ? 'Next' : 'Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
