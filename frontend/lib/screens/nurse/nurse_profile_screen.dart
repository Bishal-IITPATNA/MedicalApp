import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class NurseProfileScreen extends StatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.get('/api/nurse/profile');
      
      if (response['success'] && mounted) {
        final data = response['data'];
        setState(() {
          _profileData = data;
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _qualificationController.text = data['qualification'] ?? '';
          _experienceController.text = data['experience_years']?.toString() ?? '';
          _consultationFeeController.text = data['consultation_fee']?.toString() ?? '';
          _addressLine1Controller.text = data['address_line1'] ?? '';
          _addressLine2Controller.text = data['address_line2'] ?? '';
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
          _pinCodeController.text = data['pin_code'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiService.put('/api/nurse/profile', {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'qualification': _qualificationController.text,
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'consultation_fee': double.tryParse(_consultationFeeController.text) ?? 0.0,
        'address_line1': _addressLine1Controller.text,
        'address_line2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pin_code': _pinCodeController.text,
      });

      if (!mounted) return;
      Navigator.pop(context);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        _loadProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple.shade100,
                    child: Icon(Icons.local_hospital, size: 50, color: Colors.purple.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profileData?['name'] ?? 'Nurse',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profileData?['qualification'] ?? 'Healthcare Professional',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Button
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Profile Form
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _qualificationController,
              label: 'Qualification',
              icon: Icons.school,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _experienceController,
              label: 'Experience (Years)',
              icon: Icons.work,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _consultationFeeController,
              label: 'Consultation Fee (₹)',
              icon: Icons.currency_rupee,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Address Section
            const Text(
              'Address Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressLine1Controller,
              label: 'Address Line 1',
              icon: Icons.home,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressLine2Controller,
              label: 'Address Line 2',
              icon: Icons.home_outlined,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                    enabled: _isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _stateController,
                    label: 'State',
                    icon: Icons.map,
                    enabled: _isEditing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pinCodeController,
              label: 'PIN Code',
              icon: Icons.pin_drop,
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),

            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadProfile();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
