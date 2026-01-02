import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

// ✅ NEW: import forgot password page
import 'forgot_password_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _pillField(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: mycolors.textPrimary.withOpacity(0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      );

  String? _validateCurrent(String? v) {
    if ((v ?? '').isEmpty) return 'Required';
    return null;
  }

  String? _validateNew(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (text.length < 8) return 'At least 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(text);
    final hasNumber = RegExp(r'\d').hasMatch(text);
    if (!hasLetter || !hasNumber) return 'Include letters and numbers';
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) return 'Required';
    if (v != _newCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No logged-in user.',
        );
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'no-email',
          message: 'This account has no email on Auth.',
        );
      }

      // ✅ 1) Re-authenticate (required)
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);

      // ✅ 2) Update password
      await user.updatePassword(_newCtrl.text);

      if (!mounted) return;

      // success popup
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Password Changed'),
            content: const Text('Your password has been changed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final msg = switch (e.code) {
        'wrong-password' => 'Current password is incorrect.',
        'invalid-credential' => 'Current password is incorrect.',
        'weak-password' => 'New password is too weak.',
        'requires-recent-login' =>
          'Please login again, then try changing your password.',
        'no-user' => 'Please login first.',
        'no-email' => 'Account email not found. Please login again.',
        _ => e.message ?? 'Failed to update password.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update password')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ✅ NEW: go to forgot password page (uses current user email if available)
  void _goForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mycolors.Primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Top-right back arrow
            Positioned(
              right: 16,
              top: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.maybePop(context),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child:
                        Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
                  ),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  'CHANGE PASSWORD',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                        fontSize: mysizes.fontLg,
                      ),
                ),
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentCtrl,
                          obscureText: _hideCurrent,
                          style: const TextStyle(
                            fontSize: mysizes.fontSm,
                          ),
                          validator: _validateCurrent,
                          decoration: _pillField('Current Password').copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _hideCurrent = !_hideCurrent),
                              icon: Icon(_hideCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.remove_red_eye_outlined),
                              color: mycolors.iconColor ?? Colors.black54,
                            ),
                          ),
                        ),

                        // ✅ NEW: Forgot current password link
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _goForgotPassword,
                            child: const Text(
                              'Forgot current password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _newCtrl,
                          obscureText: _hideNew,
                          style: const TextStyle(
                            fontSize: mysizes.fontSm,
                          ),
                          validator: _validateNew,
                          decoration: _pillField('New Password').copyWith(
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _hideNew = !_hideNew),
                              icon: Icon(_hideNew
                                  ? Icons.visibility_off_outlined
                                  : Icons.remove_red_eye_outlined),
                              color: mycolors.iconColor ?? Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _hideConfirm,
                          style: const TextStyle(
                            fontSize: mysizes.fontSm,
                          ),
                          validator: _validateConfirm,
                          decoration:
                              _pillField('Re-enter New Password').copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _hideConfirm = !_hideConfirm),
                              icon: Icon(_hideConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.remove_red_eye_outlined),
                              color: mycolors.iconColor ?? Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: mycolors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: const StadiumBorder(),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Change',
                              style: TextStyle(fontSize: mysizes.fontSm)),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
