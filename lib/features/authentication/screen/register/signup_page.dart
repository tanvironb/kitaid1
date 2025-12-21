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
  final _ic = TextEditingController(); // IC or Passport
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

  /// ✅ Normalize ID same as login:
  /// Uppercase + keep only A-Z and 0-9.
  String _normalizeLoginId(String input) {
    return input
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// ✅ Convert ID to FirebaseAuth "email"
  String _idToAuthEmail(String normalizedId) => '$normalizedId@kitaid.my';

  Future<void> _onNext() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    try {
      final phoneFull = _formatMalaysiaPhone(_phone.text);

      final rawId = _ic.text.trim(); // can be IC or passport
      final normalizedId = _normalizeLoginId(rawId);

      if (normalizedId.length < 6) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid IC/Passport number.')),
        );
        return;
      }

      final authEmail = _idToAuthEmail(normalizedId);

      // 1) Create account in Firebase Auth using ID-based email
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: authEmail,
        password: _password.text,
      );

      final uid = cred.user!.uid;

      // 2) Save profile in Firestore
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'Name': _name.text.trim(),
        'Email': _email.text.trim(), // real email
        'Phone No': phoneFull,

        // ✅ login mapping fields
        'AuthEmail': authEmail,
        'LoginId': rawId,
        'LoginIdNormalized': normalizedId,

        // optional legacy fields (so older code still works)
        // You can keep these OR remove later once everything is stable:
        'IC No': rawId,
        'Passport No': rawId,

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
              'loginId': rawId,
              'loginIdNormalized': normalizedId,
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
        'email-already-in-use' => 'This IC/Passport is already registered.',
        'invalid-email' => 'Invalid IC/Passport format.',
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
                        ?.copyWith(color: Colors.white,
                        fontSize: mysizes.fontLg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 80),

                  TextFormField(
                    controller: _name,
                    validator: _req,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: const InputDecoration(
                      hintText: mytitle.s_name,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _ic,
                    validator: _req,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'IC / Passport No',
                      filled: true,
                      fillColor: Colors.white,
                      
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _email,
                    validator: _emailV,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: const InputDecoration(
                      hintText: mytitle.s_email,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phone,
                    validator: _phoneV,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: mytitle.phoneno,
                      filled: true,
                      fillColor: Colors.white,
                     
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: mysizes.fontSm),
                        child: Text(
                          '+60',
                          style: TextStyle(
                            fontSize: mysizes.fontSm,
                            color: Color.fromARGB(255, 82, 82, 82),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),

                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePw,
                    validator: _pwV,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: mytitle.s_password,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePw = !_obscurePw),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    validator: _confirmV,
                    style: TextStyle(
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: mytitle.retypepassword,
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
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
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                                
                              )
                            : const Text('Next',
                            style: TextStyle(
                              fontSize: mysizes.fontSm,
                            ),),
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
