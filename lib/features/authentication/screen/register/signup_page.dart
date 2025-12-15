// lib/features/auth/signup/signup_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:kitaid1/utilities/constant/texts.dart';
import 'signup_otp_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _ic = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(); // local number only
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _ic.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailV(String? v) {
    if (_req(v) != null) return 'Required';
    final e = v!.trim();
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e);
    return ok ? null : 'Invalid email';
  }

  /// Malaysia phone validation (without +60)
  String? _phoneV(String? v) {
    if (_req(v) != null) return 'Required';
    final p = v!.replaceAll(RegExp(r'\D'), '');
    if (p.length < 9 || p.length > 10) return 'Invalid Malaysian phone number';
    return null;
  }

  String? _pwV(String? v) {
    if (_req(v) != null) return 'Required';
    if (v!.length < 8) return 'Min 8 characters';
    return null;
  }

  String? _confirmV(String? v) {
    if (_req(v) != null) return 'Required';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  /// Normalize to +60XXXXXXXXX
  String _formatMalaysiaPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return '+60$digits';
  }

  /// Convert IC to an "email" for FirebaseAuth login
  /// Example: 050101101010 -> 050101101010@kitaid.my
  String _icToAuthEmail(String ic) {
    final digits = ic.replaceAll(RegExp(r'\D'), '');
    return '$digits@kitaid.my';
  }

  Future<void> _onNext() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    try {
      final phoneFull = _formatMalaysiaPhone(_phone.text);
      final icRaw = _ic.text.trim();
      final authEmail = _icToAuthEmail(icRaw);

      // 1) Create account in Firebase Auth using IC-based email
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: authEmail,
        password: _password.text,
      );

      final uid = cred.user!.uid;

      // 2) Save profile in Firestore (store real email + IC + phone)
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'Email': _email.text.trim(),     // real email (for contact)
        'AuthEmail': authEmail,          // optional, for debugging/login mapping
        'IC No': icRaw,
        'Name': _name.text.trim(),
        'Phone No': phoneFull,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _loading = false);

      // 3) Go to OTP page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SignUpOtpPage(
            phoneNumber: phoneFull,
            signupPayload: {
              'uid': uid,
              'name': _name.text.trim(),
              'ic': icRaw,
              'email': _email.text.trim(),
              'phone': phoneFull,
            },
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      final msg = switch (e.code) {
        'email-already-in-use' => 'This IC is already registered.',
        'invalid-email' => 'Invalid IC format.',
        'weak-password' => 'Password is too weak.',
        _ => e.message ?? 'Signup failed. Try again.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: mycolors.Primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    mytitle.signupTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 80),

                  TextFormField(
                    controller: _name,
                    validator: _req,
                    decoration: const InputDecoration(
                      labelText: mytitle.s_name,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ic,
                    validator: _req,
                    decoration: const InputDecoration(
                      labelText: mytitle.s_icno,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _email,
                    validator: _emailV,
                    decoration: const InputDecoration(
                      labelText: mytitle.s_email,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phone,
                    validator: _phoneV,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: mytitle.phoneno,
                      filled: true,
                      fillColor: Colors.white,
                      prefixText: '+60 ',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePw,
                    validator: _pwV,
                    decoration: InputDecoration(
                      labelText: mytitle.s_password,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePw ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePw = !_obscurePw),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    validator: _confirmV,
                    decoration: InputDecoration(
                      labelText: mytitle.retypepassword,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  Center(
                    child: SizedBox(
                      width: w * 0.3,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onNext,
                        child: _loading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Text('Next'),
                      ),
                    ),
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
