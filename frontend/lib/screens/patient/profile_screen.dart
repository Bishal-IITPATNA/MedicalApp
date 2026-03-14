import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Profile fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String _gender = 'Male';
  String _bloodGroup = 'A+';
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/auth/me');
      print('Profile response: $response'); // Debug log
      
      if (response['success'] && mounted) {
        final userData = response['data']['user'];
        final profileData = response['data']['profile'];
        
        print('User data: $userData'); // Debug log
        print('Profile data: $profileData'); // Debug log
        
        setState(() {
          _email = userData['email'];
          if (profileData != null) {
            _nameController.text = profileData['name'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';
            _addressController.text = profileData['address'] ?? '';
            _cityController.text = profileData['city'] ?? '';
            _stateController.text = profileData['state'] ?? '';
            _pincodeController.text = profileData['pincode'] ?? '';
            _dateOfBirthController.text = profileData['date_of_birth'] ?? '';
            // Capitalize first letter of gender to match dropdown options
            final gender = profileData['gender'] ?? 'Male';
            _gender = gender[0].toUpperCase() + gender.substring(1).toLowerCase();
            print('Normalized gender: $_gender'); // Debug
            _bloodGroup = profileData['blood_group'] ?? 'A+';
          } else {
            print('Profile data is null - user may not have completed profile during registration');
          }
        });
      } else {
        print('API call failed: ${response['error']}'); // Debug log
      }
    } catch (e) {
      print('Exception loading profile: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.put('/api/patient/profile', {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'date_of_birth': _dateOfBirthController.text,
        'gender': _gender.toLowerCase(),
        'blood_group': _bloodGroup,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile(); // Reload to discard changes
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Information
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge,
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
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        hintText: 'YYYY-MM-DD',
                      ),
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Other'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _isEditing ? (value) {
                        setState(() => _gender = value ?? 'Male');
                      } : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _bloodGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        prefixIcon: Icon(Icons.bloodtype),
                        border: OutlineInputBorder(),
                      ),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _isEditing ? (value) {
                        setState(() => _bloodGroup = value ?? 'A+');
                      } : null,
                    ),
                    const SizedBox(height: 32),

                    // Address Information
                    Text(
                      'Address Information',
                      style: Theme.of(context).textTheme.titleLarge,
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
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
