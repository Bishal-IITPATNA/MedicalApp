import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(); // Changed from _emailController
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // First, check what roles the user has
    final result = await _authService.checkUserRoles(
      _loginController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        final availableRoles = List<String>.from(result['data']['available_roles']);
        
        if (availableRoles.length == 1) {
          // User has single role, login directly
          await _loginWithRole(availableRoles.first);
        } else if (availableRoles.length > 1) {
          // User has multiple roles, show selection dialog
          await _showRoleSelectionDialog(availableRoles);
        } else {
          // No roles found (shouldn't happen if login is successful)
          _showError('No valid roles found for this account');
        }
      } else {
        _showError(result['error'] ?? 'Login failed');
      }
    }
  }

  Future<void> _loginWithRole(String role) async {
    setState(() => _isLoading = true);

    final result = await _authService.loginWithRole(
      _loginController.text.trim(),
      _passwordController.text,
      role,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        _navigateToRoleDashboard(role);
      } else {
        _showError(result['error'] ?? 'Login failed');
      }
    }
  }

  void _navigateToRoleDashboard(String role) {
    String route = '/patient-dashboard';
    switch (role) {
      case 'doctor':
        route = '/doctor-dashboard';
        break;
      case 'nurse':
        route = '/nurse-dashboard';
        break;
      case 'admin':
        route = '/admin-dashboard';
        break;
      case 'medical_store':
        route = '/medical-store-dashboard';
        break;
      case 'lab_store':
        route = '/lab-store-dashboard';
        break;
      default:
        route = '/patient-dashboard';
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _showRoleSelectionDialog(List<String> availableRoles) async {
    final selectedRole = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You have multiple roles. Please select one to continue:'),
            const SizedBox(height: 16),
            ...availableRoles.map((role) => ListTile(
              leading: Icon(
                _getRoleIcon(role),
                color: Theme.of(context).primaryColor,
              ),
              title: Text(_formatRoleName(role)),
              onTap: () => Navigator.of(context).pop(role),
            )),
          ],
        ),
      ),
    );

    if (selectedRole != null) {
      await _loginWithRole(selectedRole);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'medical_store':
        return Icons.local_pharmacy;
      case 'lab_store':
        return Icons.science;
      default:
        return Icons.person;
    }
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'medical_store':
        return 'Medical Store';
      case 'lab_store':
        return 'Lab Store';
      default:
        return role.substring(0, 1).toUpperCase() + role.substring(1);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 80,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Seevak Care',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to your account',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  TextFormField(
                    controller: _loginController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Email or Mobile Number',
                      prefixIcon: Icon(Icons.alternate_email),
                      helperText: 'Enter your email address or mobile number',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or mobile number';
                      }
                      // Basic validation for email or mobile
                      if (value.contains('@')) {
                        // Email validation
                        if (!value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                      } else {
                        // Mobile validation
                        if (value.length < 10) {
                          return 'Please enter a valid mobile number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Don\'t have an account? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
