import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/audit_service.dart';
import 'main_dashboard.dart';
import 'two_factor_auth_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: 'admin@police.gov.in');
  final TextEditingController _passwordController = TextEditingController(text: 'Admin@123456');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String adminPhone = '+919876543210';

    try {
      // Sign in with Firebase Authentication — this MUST succeed before proceeding
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      bool is2FAEnabled = true;

      // Ensure admin profile exists in Firestore with super_admin role & active status
      try {
        final uid = userCredential.user?.uid;
        if (uid != null) {
          final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
          final doc = await userDocRef.get().timeout(const Duration(seconds: 3));
          if (doc.exists) {
            final data = doc.data();
            if (data?['twoFactorAuthEnabled'] != null) {
              is2FAEnabled = data!['twoFactorAuthEnabled'] == true;
            }
            final phone = (data?['phone'] ?? data?['phoneNumber'])?.toString();
            if (phone != null && phone.isNotEmpty) {
              adminPhone = phone;
            }
            // Ensure super_admin role is set in background
            if (data?['role'] != 'super_admin' || data?['accountStatus'] != 'active') {
              userDocRef.set({
                'role': 'super_admin',
                'accountStatus': 'active',
                'designation': data?['designation'] ?? 'CP',
              }, SetOptions(merge: true));
            }
          } else {
            // Auto-create initial Master Admin document in background
            userDocRef.set({
              'name': 'Master Admin',
              'email': email,
              'role': 'super_admin',
              'accountStatus': 'active',
              'phone': adminPhone,
              'twoFactorAuthEnabled': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (_) {
        // Phone lookup is optional — use default phone for 2FA
      }

      if (!is2FAEnabled) {
        // Admin disabled 2FA in Settings -> Directly grant access!
        AuditService.logAction(
          action: 'PRIMARY_AUTH_SUCCESS_DIRECT',
          targetUserId: userCredential.user?.uid ?? 'super_admin',
          details: 'Direct login authenticated without 2FA step (2FA disabled by admin setting) for $email',
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainDashboard()),
          (route) => false,
        );
        return;
      }

      AuditService.logAction(
        action: 'PRIMARY_AUTH_SUCCESS',
        targetUserId: 'admin',
        details: 'Email/Password verified for $email. Initiating 2FA OTP step.',
      );

      if (!mounted) return;

      // Start phone verification with fast fallback to avoid blocking login UI
      bool navigated = false;
      void navigateOnce(String? vId, int? token) {
        if (!navigated) {
          navigated = true;
          _navigateTo2FA(email, adminPhone, vId, token);
        }
      }

      try {
        FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: adminPhone,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            navigateOnce(null, null);
          },
          codeSent: (String verificationId, int? resendToken) {
            navigateOnce(verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            navigateOnce(verificationId, null);
          },
        );

        // Fallback timer: if reCAPTCHA or SMS network takes more than 2.5s, proceed to 2FA view
        Future.delayed(const Duration(milliseconds: 2500), () {
          navigateOnce(null, null);
        });
      } catch (_) {
        navigateOnce(null, null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication Failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateTo2FA(String email, String phone, String? verificationId, int? resendToken) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TwoFactorAuthView(
          email: email,
          phone: phone,
          verificationId: verificationId,
          resendToken: resendToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Container(
              width: 440,
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
                        Icons.admin_panel_settings,
                        size: 44,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Master Admin Portal',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Police Management System — Admin Console',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Admin Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          _isLoading ? 'Authenticating...' : 'Sign In & Verify 2FA',
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
