import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/support_info_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final email = ModalRoute.of(context)?.settings.arguments as String?;
    if (email != null && _emailController.text.isEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      /// Step 1
      final forgotResult =
          await _authService.forgotPassword(_emailController.text.trim());

      if (!forgotResult['success']) {
        _showError(forgotResult['error']);
        return;
      }

      final resetId = forgotResult['reset_id'];

      /// Step 2
      final verifyResult = await _authService.verifyPasswordResetOTP(
        resetId,
        _tokenController.text.trim(),
      );

      if (!verifyResult['success']) {
        _showError(verifyResult['error']);
        return;
      }

      /// ✅ Step 3 (FIXED CALL)
      final result = await _authService.resetPassword(
        resetId,
        _passwordController.text,
        channel: 'email', // ✅ NAMED PARAMETER
      );

      if (mounted && result['success']) {
        _showSuccessDialog();
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String? message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Something went wrong')),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your password has been reset successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_open, size: 80),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _tokenController,
                    decoration:
                        const InputDecoration(labelText: 'Reset Token'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Token required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration:
                        const InputDecoration(labelText: 'New Password'),
                    validator: (v) =>
                        v != null && v.length >= 6
                            ? null
                            : 'Minimum 6 characters',
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    validator: (v) =>
                        v == _passwordController.text
                            ? null
                            : 'Passwords do not match',
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Reset Password'),
                  ),

                  const SizedBox(height: 24),
                  const SupportInfoWidget(showInFooter: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
``
