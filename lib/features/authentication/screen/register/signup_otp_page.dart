// lib/features/auth/signup/signup_otp_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kitaid1/features/authentication/screen/register/widgets/signup_complete_page.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:kitaid1/utilities/constant/texts.dart';
import 'widgets/otp_fields.dart';

class SignUpOtpPage extends StatefulWidget {
  const SignUpOtpPage({
    super.key,
    required this.phoneNumber,
    required this.signupPayload,
  });

  final String phoneNumber;
  final Map<String, dynamic> signupPayload;

  @override
  State<SignUpOtpPage> createState() => _SignUpOtpPageState();
}

class _SignUpOtpPageState extends State<SignUpOtpPage> {
  String _otp = '';
  bool _verifying = false;

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    setState(() => _verifying = true);

    try {
      // ✅ DEMO OTP for web (accept only 123456)
      if (_otp != '123456') {
        throw Exception('Invalid OTP (demo). Try 123456');
      }

      // ✅ mark phone verified in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user session. Please signup again.');
      }

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'phoneVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _verifying = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignUpCompletePage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _resend() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo OTP: use 123456')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mycolors.Primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
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
                Column(
                  children: const [
                    Text(
                      'Enter the OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: mysizes.fontSm,
                      ),
                    ),
                    SizedBox(height: 1),
                  ],
                ),
                const SizedBox(height: 80),
                const SizedBox(height: 24),

                // ✅ 6-digit OTP
                OtpFields(
                  length: 6,
                  onCompleted: (code) => setState(() => _otp = code),
                  onChanged: (code) => setState(() => _otp = code),
                ),

                const SizedBox(height: 100),

                Center(
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: (_otp.length == 6 && !_verifying) ? _verify : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: mycolors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
                          side: const BorderSide(color: Colors.white),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: mysizes.btnheight,
                        ),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: mycolors.textPrimary,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _resend,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: mysizes.fontSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
