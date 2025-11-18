import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';


bool _hideCurrent = true;
bool _hideNew = true;
bool _hideConfirm = true;

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    if (!hasLetter || !hasNumber) {
      return 'Include letters and numbers';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) return 'Required';
    if (v != _newCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      // TODO: connect to backend
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update password')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

            // Main content
            Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  'CHANGE PASSWORD',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        fontSize: 26, // 🔹 Increased title size
                      ),
                ),

                const Spacer(),

                // Centered form
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                       TextFormField(
                        controller: _currentCtrl,
                        obscureText: _hideCurrent,
                        validator: _validateCurrent,
                        decoration: _pillField('Current Password').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                            icon: Icon(_hideCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.remove_red_eye_outlined),
                            color: mycolors.iconColor ?? Colors.black54, // grey eye like screenshot
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // New password
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _hideNew,
                        validator: _validateNew,
                        decoration: _pillField('New Password').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideNew = !_hideNew),
                            icon: Icon(_hideNew
                                ? Icons.visibility_off_outlined
                                : Icons.remove_red_eye_outlined),
                            color: mycolors.iconColor ?? Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Confirm new password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _hideConfirm,
                        validator: _validateConfirm,
                        decoration: _pillField('Re-enter New Password').copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
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

                // Change button
                Center(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: mycolors.textPrimary,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28),
                        shape: const StadiumBorder(),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Change',
                              style: TextStyle(fontSize: 16),
                            ),
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
