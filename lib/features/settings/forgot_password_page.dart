import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

// ✅ fallback target if there's nothing to pop
import 'package:kitaid1/features/authentication/screen/login/login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _sendingOtp = false;
  bool _verifying = false;

  String? _verificationId;

  @override
  void dispose() {
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _normalize(String v) =>
      v.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  InputDecoration _pill(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
          color: mycolors.textPrimary.withOpacity(0.6),
          fontSize: mysizes.fontSm,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String? _validateId(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Required';
    if (_normalize(v!).length < 6) return 'Invalid MyKad / Passport';
    return null;
  }

  String? _validatePhone(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Required';
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(v!)) {
      return 'Use E.164 format (e.g. +60123456789)';
    }
    return null;
  }

  String? _validateOtp(String? v) {
    if ((v ?? '').trim().length < 6) return 'Enter OTP';
    return null;
  }

  String? _validateNew(String? v) {
    final t = (v ?? '').trim();
    if (t.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(t) || !RegExp(r'\d').hasMatch(t)) {
      return 'Use letters & numbers';
    }
    return null;
  }

  String? _validateConfirm(String? v) =>
      v != _newCtrl.text ? 'Passwords do not match' : null;

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sendingOtp = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneCtrl.text.trim(),
        codeSent: (id, _) {
          _verificationId = id;
          _snack('OTP sent');
        },
        verificationFailed: (e) => _snack(e.message ?? 'OTP failed'),
        verificationCompleted: (_) {},
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
        timeout: const Duration(seconds: 60),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (_verificationId == null) {
      _snack('Request OTP first');
      return;
    }

    if (_validateOtp(_otpCtrl.text) != null ||
        _validateNew(_newCtrl.text) != null ||
        _validateConfirm(_confirmCtrl.text) != null) {
      _snack('Check OTP and password fields');
      return;
    }

    setState(() => _verifying = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(cred);

      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Verified'),
          content: Text('OTP verified. Connect Cloud Function to update password.'),
        ),
      );

      // ✅ NO signOut here anymore
      _goBack();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: mycolors.Primary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 16,
              top: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _goBack,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 72),
                  Text(
                    'FORGOT PASSWORD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: mysizes.fontLg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // rest of UI unchanged...
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
