import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LabStoreProfileCompletion extends StatefulWidget {
  const LabStoreProfileCompletion({super.key});

  @override
  State<LabStoreProfileCompletion> createState() => _LabStoreProfileCompletionState();
}

class _LabStoreProfileCompletionState extends State<LabStoreProfileCompletion> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.put('/api/lab-store/profile', {
        'license_number': _licenseController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
      });

      if (mounted) {
        if (response['success']) {
          Navigator.pushReplacementNamed(context, '/lab-store-dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile completed successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to save profile'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Complete Lab Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lab Information', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _licenseController,
                      decoration: const InputDecoration(labelText: 'License Number', prefixIcon: Icon(Icons.card_membership), border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter license number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Lab Address', prefixIcon: Icon(Icons.home), border: OutlineInputBorder()),
                      maxLines: 2,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter lab address' : null,
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
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Complete Profile'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
