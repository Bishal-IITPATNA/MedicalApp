import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String _selectedRole = 'patient';
  
  final List<Map<String, String>> _roles = [
    {'value': 'patient', 'label': 'Patient'},
    {'value': 'doctor', 'label': 'Doctor'},
    {'value': 'nurse', 'label': 'Nurse'},
    {'value': 'medical_store', 'label': 'Medical Store'},
    {'value': 'lab_store', 'label': 'Lab Store'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    print('🚀 _register() function called'); // Debug logging
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed'); // Debug logging
      return;
    }
    
    print('✅ Form validation passed'); // Debug logging

    setState(() => _isLoading = true);

    final result = await _authService.register({
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    });

    print('🔍 Registration result: $result'); // Debug logging
    print('🔍 Result type: ${result.runtimeType}'); // Debug logging
    print('🔍 Success key exists: ${result.containsKey('success')}'); // Debug logging
    print('🔍 Success value: ${result['success']}'); // Debug logging
    print('🔍 Success value type: ${result['success'].runtimeType}'); // Debug logging
    print('🔍 Success == true: ${result['success'] == true}'); // Debug logging
    print('🔍 Success toString: ${result['success'].toString()}'); // Debug logging

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        print('✅ Registration successful, navigating to OTP verification'); // Debug logging
        
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              verificationData: {
                'verification_id': result['verification_id'],
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'phone_available': result['phone_available'] ?? false,
              },
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Registration failed: ${result['error']}'); // Debug logging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Register as',
                    prefixIcon: Icon(Icons.work),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role['value'],
                      child: Text(role['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
