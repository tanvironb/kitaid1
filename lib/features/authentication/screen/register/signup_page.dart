// lib/features/auth/signup/signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Controllers
  final _name = TextEditingController();
  final _ic = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
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

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailV(String? v) {
    if (_req(v) != null) return 'Required';
    final e = v!.trim();
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e);
    return ok ? null : 'Invalid email';
  }

  String? _phoneV(String? v) {
    if (_req(v) != null) return 'Required';
    final p = v!.replaceAll(RegExp(r'\D'), '');
    if (p.length < 9 || p.length > 12) return 'Invalid phone number';
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

  Future<void> _onNext() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);

    // TODO: Call your backend to create a pending user & send OTP to _phone.text
    // Simulate a short delay:
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _loading = false);

    // Navigate to OTP page, pass the phone (and anything else you need)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpOtpPage(
          phoneNumber: _phone.text.trim(),
          // You can pass any payload needed for final account creation
          signupPayload: {
            'name': _name.text.trim(),
            'ic': _ic.text.trim(),
            'email': _email.text.trim(),
            'phone': _phone.text.trim(),
            // Don't pass password in plain text to a real screen in a real app;
            // for demo we keep it, but you’d handle securely with backend/session.
            'password': _password.text,
          },
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: mycolors.Primary, // Blue page background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Header =====
                Text(
                  mytitle.signupTitle, // "signup"
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Column(
                  children: [
                    const Text(
                      'Create Your Account',
                      style: TextStyle(color: Colors.white,fontSize:mysizes.fontSm ),
                    ),
                    const SizedBox(height: mysizes.sm),
                  ]
                ),
                const SizedBox(height: 80),


 // Name
                   Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center, 
                   children: [
                    TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  decoration: const InputDecoration(
                    labelText: mytitle.s_name,
                    // force white field
                    filled: true,
                    fillColor: Colors.white,                                   
                  ),
                ),
                ],
                ),
                    const SizedBox(height: 12),
                    

// IC No.
                    Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center, 
                   children: [
                    TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  decoration: const InputDecoration(
                    labelText: mytitle.s_icno,
                    // force white field
                    filled: true,
                    fillColor: Colors.white,                                   
                  ),
                ),
                ],
                ),
                    const SizedBox(height: 12),

 // Email
                    Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center, 
                   children: [
                    TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  decoration: const InputDecoration(
                    labelText: mytitle.s_email,
                    // force white field
                    filled: true,
                    fillColor: Colors.white,                                   
                  ),
                ),
                ],
                ),
                    const SizedBox(height: 12),

// Phone
                    Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center, 
                   children: [
                    TextFormField(
                      style: const TextStyle(color: mycolors.textPrimary, fontSize: mysizes.fontSm),
                  decoration: const InputDecoration(
                    labelText: mytitle.phoneno,
                    // force white field
                    filled: true,
                    fillColor: Colors.white,                                   
                  ),
                ),
                ],
                ),
                    const SizedBox(height: 12),

// Password
                   Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _password,
                       obscureText: _obscurePw, // hides password
                      validator: _pwV,
                      style: const TextStyle(
                        color: mycolors.textPrimary,
                        fontSize: mysizes.fontSm,
                      ),
                      decoration: InputDecoration(
                        labelText: mytitle.s_password, // ✅ uses your text constant
                        filled: true,
                        fillColor: Colors.white,       // ✅ white background
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePw ? Icons.visibility_off : Icons.visibility,
                            color: mycolors.textPrimary,
                          ),
                          onPressed: () => setState(() {
                            _obscurePw = !_obscurePw;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),

                    const SizedBox(height: 12),

// Confirm Password
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscureConfirm,
                        validator: _confirmV,
                        style: const TextStyle(
                          color: mycolors.textPrimary,
                          fontSize: mysizes.fontSm,
                        ),
                       decoration: InputDecoration(
                          labelText: mytitle.retypepassword, // ✅ uses your text constant
                          filled: true,
                          fillColor: Colors.white,           // ✅ white background
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: mycolors.textPrimary,
                            ),
                           onPressed: () => setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  

                    const SizedBox(height: 70),

// Next button – matches your wide button style
                    Center(
                      child: SizedBox(
                        width: w * 0.3, // match your signup button width behavior
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mycolors.bgPrimary, // adjust if needed
                            foregroundColor: mycolors.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: mysizes.btnheight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      ;
    ;
  }
}
