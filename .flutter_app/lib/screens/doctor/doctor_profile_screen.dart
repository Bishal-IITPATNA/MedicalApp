import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  int _selectedTab = 0; // 0 = Profile, 1 = Chambers
  
  // Profile fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  String? _email;
  
  // Chambers data
  List<Map<String, dynamic>> _chambers = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadChambers(); // Load chambers on initialization
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _experienceYearsController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/auth/me');
      print('Profile response: $response');
      
      if (response['success'] && mounted) {
        final userData = response['data']['user'];
        final profileData = response['data']['profile'];
        
        print('User data: $userData');
        print('Profile data: $profileData');
        
        setState(() {
          _email = userData['email'];
          if (profileData != null) {
            _nameController.text = profileData['name'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';
            _addressController.text = profileData['address'] ?? '';
            _cityController.text = profileData['city'] ?? '';
            _stateController.text = profileData['state'] ?? '';
            _pincodeController.text = profileData['pincode'] ?? '';
            _specialtyController.text = profileData['specialty'] ?? '';
            _qualificationController.text = profileData['qualification'] ?? '';
            _experienceYearsController.text = profileData['experience_years']?.toString() ?? '';
            _consultationFeeController.text = profileData['consultation_fee']?.toString() ?? '';
            
            // Don't load chambers from profile - they should come from separate chambers endpoint
            // This prevents profile address from being overwritten by chamber data
          } else {
            print('Profile data is null - doctor may not have completed profile');
          }
        });
      } else {
        print('API call failed: ${response['error']}');
      }
      
      // Load chambers data
      await _loadChambers();
    } catch (e) {
      print('Exception loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadChambers() async {
    print('Loading chambers...');
    try {
      final response = await _apiService.get('/api/doctor/chambers');
      print('Chambers response: $response');
      if (response['success'] && mounted) {
        final chambersData = response['data']['chambers'] ?? [];
        print('Chambers data: $chambersData');
        setState(() {
          _chambers = List<Map<String, dynamic>>.from(chambersData);
        });
        print('Chambers loaded: ${_chambers.length} chambers');
      } else {
        print('Failed to load chambers: ${response['error']}');
      }
    } catch (e) {
      print('Error loading chambers: $e');
    }
  }
  
  Future<void> _saveChambers() async {
    try {
      final response = await _apiService.put('/api/doctor/chambers', {
        'chambers': _chambers,
      });
      
      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chambers updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to update chambers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating chambers: $e')),
        );
      }
    }
  }
  
  void _addChamber() {
    setState(() {
      _chambers.add({
        'name': '',
        'address': '',
        'city': '',
        'state': '',
        'pincode': '',
        'consultation_fee': 0.0,
        'available_from': '09:00 AM',
        'available_to': '05:00 PM',
        'available_days': [], // Add available days field
      });
    });
  }
  
  void _removeChamber(int index) {
    setState(() {
      _chambers.removeAt(index);
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.put('/api/doctor/profile', {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'specialty': _specialtyController.text,
        'qualification': _qualificationController.text,
        'experience_years': int.tryParse(_experienceYearsController.text) ?? 0,
        'consultation_fee': double.tryParse(_consultationFeeController.text) ?? 0.0,
      });

      if (response['success'] && mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.teal,
          actions: [
            if (!_isEditing && _selectedTab == 0)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              )
            else if (_isEditing && _selectedTab == 0)
              TextButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  _loadProfile(); // Reload to discard changes
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() => _selectedTab = index);
              if (index == 1) {
                _loadChambers(); // Load chambers when Chambers tab is selected
              }
            },
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.business), text: 'Chambers'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfileTab(),
                  _buildChambersTab(),
                ],
              ),
      ),
    );
  }
  
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_email != null)
                    Text(
                      _email!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: Colors.teal.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Doctor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Information
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // Professional Information
                    Text(
                      'Professional Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _specialtyController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _qualificationController,
                      decoration: const InputDecoration(
                        labelText: 'Qualification',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., MBBS, MD',
                      ),
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _experienceYearsController,
                      decoration: const InputDecoration(
                        labelText: 'Experience (years)',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _consultationFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Consultation Fee (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // Address Information
                    Text(
                      'Address Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        prefixIcon: Icon(Icons.pin_drop),
                        border: OutlineInputBorder(),
                      ),
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.teal,
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                  ],
                ),
              ),
            );
  }
  
  Widget _buildChambersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Practice Locations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.teal, size: 32),
                onPressed: _addChamber,
                tooltip: 'Add Chamber',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your practice locations and availability',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          if (_chambers.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chambers added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your practice locations to get started',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Chamber'),
                    onPressed: _addChamber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_chambers.length, (index) {
              return _buildChamberCard(index);
            }),
          
          if (_chambers.isNotEmpty)
            const SizedBox(height: 16),
          
          if (_chambers.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChambers,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Save All Chambers'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChamberCard(int index) {
    final chamber = _chambers[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  'Chamber ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeChamber(index),
                  tooltip: 'Remove Chamber',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: chamber['name'],
              decoration: const InputDecoration(
                labelText: 'Chamber Name',
                hintText: 'e.g., City Hospital',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _chambers[index]['name'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: chamber['address'],
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _chambers[index]['address'] = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['city'],
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['city'] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['state'],
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['state'] = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['pincode'],
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      prefixIcon: Icon(Icons.pin_drop),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['pincode'] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['consultation_fee']?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Fee (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['consultation_fee'] = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['available_from'],
                    decoration: const InputDecoration(
                      labelText: 'From Time',
                      hintText: '09:00 AM',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['available_from'] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: chamber['available_to'],
                    decoration: const InputDecoration(
                      labelText: 'To Time',
                      hintText: '05:00 PM',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _chambers[index]['available_to'] = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Available Days Selection
            const Text(
              'Available Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
              ].map((day) {
                final isSelected = (chamber['available_days'] as List<dynamic>?)?.contains(day) ?? false;
                return FilterChip(
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.teal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      List<dynamic> days = List.from(chamber['available_days'] ?? []);
                      if (selected) {
                        if (!days.contains(day)) days.add(day);
                      } else {
                        days.remove(day);
                      }
                      _chambers[index]['available_days'] = days;
                    });
                  },
                  selectedColor: Colors.teal,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide(color: Colors.teal.shade200),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
