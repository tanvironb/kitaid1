// lib/features/auth/signup/signup_complete_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class SignUpCompletePage extends StatelessWidget {
  const SignUpCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mycolors.Primary, // Blue background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ White tick icon
                  const Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),

                  // ✅ White title text
                  const Text(
                    'Verification Complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: mysizes.fontLg,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ✅ White subtitle text
                  const Text(
                    'Your account has been verified successfully.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: mysizes.fontSm,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ✅ Keep original button color (do not change)
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                      child: const Text('Login'),
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
