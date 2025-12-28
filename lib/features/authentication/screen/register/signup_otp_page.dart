// lib/features/auth/signup/signup_otp_page.dart
import 'package:flutter/foundation.dart' show kIsWeb;
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

  final String phoneNumber; // Must be in E.164 e.g. +60123456789
  final Map<String, dynamic> signupPayload;

  @override
  State<SignUpOtpPage> createState() => _SignUpOtpPageState();
}

class _SignUpOtpPageState extends State<SignUpOtpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _otp = '';
  bool _sending = false;
  bool _verifying = false;
  bool _cancelling = false;

  // For Android/iOS phone auth
  String? _verificationId;
  int? _resendToken;

  // For web phone auth
  ConfirmationResult? _webConfirmation;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  String _normalizePhone(String raw) => raw.trim();

  Future<void> _sendOtp({bool forceResend = false}) async {
    final phone = _normalizePhone(widget.phoneNumber);

    setState(() => _sending = true);

    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(phone);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          timeout: const Duration(seconds: 60),
          forceResendingToken: forceResend ? _resendToken : null,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _applyCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP failed: ${e.code} - ${e.message}')),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            _resendToken = resendToken;

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP sent to ${widget.phoneNumber}')),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }

      if (!mounted) return;
      setState(() => _sending = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  Future<void> _verify() async {
    if (_otp.length != 6 || _verifying) return;

    setState(() => _verifying = true);

    try {
      if (kIsWeb) {
        final confirm = _webConfirmation;
        if (confirm == null) {
          throw Exception('OTP session not found. Please resend OTP.');
        }
        final userCred = await confirm.confirm(_otp);
        await _afterVerified(userCred.user);
      } else {
        final vid = _verificationId;
        if (vid == null) {
          throw Exception('Verification ID missing. Please resend OTP.');
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: vid,
          smsCode: _otp,
        );

        await _applyCredential(credential);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _applyCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user session. Please signup again.');
    }

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        // ok
      } else if (e.code == 'credential-already-in-use') {
        throw Exception('This phone number is already used by another account.');
      } else if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid OTP code.');
      } else {
        throw Exception(e.message ?? 'Failed to verify OTP.');
      }
    }

    await _afterVerified(_auth.currentUser);
  }

  Future<void> _afterVerified(User? user) async {
    if (user == null) throw Exception('User not found after verification.');

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      ...widget.signupPayload,
      'phoneNumber': widget.phoneNumber,
      'phoneVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _verifying = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpCompletePage()),
    );
  }

  Future<void> _resend() async {
    if (_sending) return;
    await _sendOtp(forceResend: true);
  }

  /// ✅ This fixes "IC/Passport already registered" after going back.
  /// It cancels the signup by deleting the just-created Auth user + Firestore user doc.
  Future<void> _cancelAndGoBack() async {
    if (_cancelling) return;

    setState(() => _cancelling = true);

    try {
      final user = _auth.currentUser;

      if (user != null) {
        // delete Firestore doc (optional but recommended)
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).delete();

        // delete Auth user (removes the IC/Passport "email" registration)
        await user.delete();
      }

      await _auth.signOut();

      if (!mounted) return;
      Navigator.pop(context); // back to SignUpPage
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not go back: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mycolors.Primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _cancelling ? null : _cancelAndGoBack,
        ),
      ),
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

                if (_sending || _cancelling)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                const SizedBox(height: 24),

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
                      onPressed: (_otp.length == 6 && !_verifying && !_sending && !_cancelling)
                          ? _verify
                          : null,
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
                  onPressed: (_sending || _cancelling) ? null : _resend,
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
