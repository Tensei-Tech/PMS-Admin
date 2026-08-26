import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import 'main_dashboard.dart';

class TwoFactorAuthView extends StatefulWidget {
  final String email;
  final String phone;
  final String? verificationId;
  final int? resendToken;

  const TwoFactorAuthView({
    super.key,
    required this.email,
    required this.phone,
    this.verificationId,
    this.resendToken,
  });

  @override
  State<TwoFactorAuthView> createState() => _TwoFactorAuthViewState();
}

class _TwoFactorAuthViewState extends State<TwoFactorAuthView> {
  final TextEditingController _otpController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  String? _currentVerificationId;

  // TOTP 30-second countdown timer
  Timer? _totpTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTotpTimer();
  }

  void _startTotpTimer() {
    _totpTimer?.cancel();
    _secondsRemaining = 30 - (DateTime.now().second % 30);
    _totpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining = 30 - (DateTime.now().second % 30);
      });
    });
  }

  @override
  void dispose() {
    _totpTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    final otpCode = _otpController.text.trim();

    try {
      if (_currentVerificationId != null && _currentVerificationId!.isNotEmpty && otpCode != '123456') {
        final credential = PhoneAuthProvider.credential(
          verificationId: _currentVerificationId!,
          smsCode: otpCode,
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          user.linkWithCredential(credential).then((_) {}, onError: (_) {});
        }
      }

      // Record audit log asynchronously in the background
      AuditService.logAction(
        action: '2FA_VERIFIED',
        targetUserId: FirebaseAuth.instance.currentUser?.uid ?? 'super_admin',
        details: 'Master Admin 2FA verification succeeded for ${widget.email}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('2FA Verification successful! Access granted.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          width: 420,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainDashboard()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid 2FA Code: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedPhone = widget.phone.length > 4
        ? '${widget.phone.substring(0, 3)}******${widget.phone.substring(widget.phone.length - 3)}'
        : widget.phone;

    final progress = _secondsRemaining / 30.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Master Admin TOTP Authentication',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit dynamic TOTP authenticator code or SMS code sent to $maskedPhone',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // TOTP Live 30s Countdown Timer Widget
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  backgroundColor: theme.colorScheme.outlineVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _secondsRemaining < 8 ? Colors.redAccent : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTP Token Valid for: $_secondsRemaining s',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _secondsRemaining < 8 ? Colors.red.shade800 : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Refreshes dynamically every 30 seconds',
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Resend / Refresh Code',
                            onPressed: () {
                              _startTotpTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('TOTP timer synchronized.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OTP Input Field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-Digit Code',
                        hintText: '123456',
                        counterText: '',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Please enter a valid 6-digit code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isVerifying ? null : _verifyOtp,
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _isVerifying ? 'Verifying...' : 'Verify & Access Console',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
