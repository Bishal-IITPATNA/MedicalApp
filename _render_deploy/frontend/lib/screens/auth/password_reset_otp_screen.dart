import 'package:flutter/material.dart';
import '../../widgets/support_info_widget.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import 'new_password_screen.dart';

class PasswordResetOTPScreen extends StatefulWidget {
  final Map<String, dynamic> resetData;

  const PasswordResetOTPScreen({
    super.key,
    required this.resetData,
  });

  @override
  State<PasswordResetOTPScreen> createState() => _PasswordResetOTPScreenState();
}

class _PasswordResetOTPScreenState extends State<PasswordResetOTPScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();
  
  bool _isLoading = false;
  // Email is the only password-reset channel now.
  static const bool _usePhone = false;
  int _remainingSeconds = 600; // 10 minutes
  Timer? _timer;
  bool _canResend = false;
  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }

        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.verifyPasswordResetOTP(
      int.parse(widget.resetData['reset_id'].toString()),
      otp,
      _usePhone ? 'phone' : 'email',
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        // Navigate to new password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(
              resetId: widget.resetData['reset_id'],
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    final result = await _authService.resendPasswordResetOTP(
      widget.resetData['reset_id'],
      _usePhone ? 'phone' : 'email',
    );

    setState(() {
      _isLoading = false;
      _canResend = false;
      _resendCooldown = 30;
      _remainingSeconds = 600; // Reset to 10 minutes
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'OTP resent successfully'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Password Reset Verification',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent a 6-digit OTP to your email',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.resetData['email'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify OTP', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              if (_remainingSeconds > 0)
                Text(
                  'OTP expires in ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _canResend && !_isLoading ? _resendOTP : null,
                child: Text(
                  _canResend
                      ? 'Resend OTP'
                      : 'Resend OTP in ${_resendCooldown}s',
                  style: TextStyle(
                    color: _canResend ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SupportInfoWidget(showInFooter: true),
            ],
          ),
        ),
      ),
    );
  }
}
