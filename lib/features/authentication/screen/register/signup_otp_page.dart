// lib/features/auth/signup/signup_otp_page.dart
import 'package:flutter/material.dart';
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
    if (_otp.length != 4) return;

    setState(() => _verifying = true);

    // TODO: Verify OTP with your backend here using widget.signupPayload + _otp
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _verifying = false);

    // On success go to the "Verification Complete" page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignUpCompletePage(),
      ),
    );
  }

  Future<void> _resend() async {
    // TODO: trigger resend OTP via backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Enter the OTP',
                      style: TextStyle(color: Colors.white,fontSize:mysizes.fontSm ),
                    ),
                    const SizedBox(height:1),
                  ]
                ),
                const SizedBox(height: 80),
                  const SizedBox(height: 24),

                  // 4 OTP boxes with auto-advance & paste support
                  OtpFields(
                    length: 4,
                    onCompleted: (code) => _otp = code,
                    onChanged: (code) => _otp = code,
                  ),

                  const SizedBox(height: 100),

                  // Verify button
                  Center(
                 child: SizedBox(
                   width: 180, //  set your desired button width
                   child: ElevatedButton(
                     onPressed: (_otp.length == 4 && !_verifying) ? _verify : null,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white,              // white fill
                       foregroundColor: mycolors.textPrimary,      // dark text color
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
                      foregroundColor: Colors.white, // ✅ text color white
                      padding: EdgeInsets.zero,      // removes extra spacing
                      textStyle: const TextStyle(
                        decoration: TextDecoration.underline, // ✅ underline text
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
