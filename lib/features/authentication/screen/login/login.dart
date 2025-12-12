import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';
import 'package:kitaid1/features/authentication/screen/register/signup_page.dart';
import 'package:kitaid1/features/services/biometric_auth_service.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:kitaid1/utilities/constant/texts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _sheetFade;

  bool _hidePassword = true;

  final _icController = TextEditingController();
  final _pwController = TextEditingController();

  // ✅ Biometric state
  bool _bioSupported = false;
  bool _bioEnabled = false;
  bool _bioLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _sheetFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.85)),
    );

    _controller.forward();

    // ✅ Load biometric availability + user preference
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final bio = BiometricAuthService.instance;
    final supported = await bio.isDeviceSupported();
    final enabled = await bio.isEnabled();

    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
    });
  }

  Future<void> _biometricLogin() async {
    if (_bioLoading) return;

    final bio = BiometricAuthService.instance;

    // re-check in case user changed settings
    final supported = await bio.isDeviceSupported();
    final enabled = await bio.isEnabled();

    if (!supported || !enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric login is not enabled.')),
      );
      return;
    }

    setState(() => _bioLoading = true);

    final ok = await bio.authenticate(reason: 'Login to KitaID');

    if (!mounted) return;
    setState(() => _bioLoading = false);

    if (!ok) return;

    // ✅ For now, go to home. Later, check FirebaseAuth currentUser.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _icController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  InputDecoration _pillDecoration({
    required String hint,
    required Widget suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.45),
        fontSize: mysizes.fontSm,
      ),
      filled: true,
      fillColor: Colors.grey.shade400.withOpacity(0.65),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(
          color: mycolors.Primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: suffix,
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final showBiometricButton = _bioSupported && _bioEnabled;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ===== SAME BACKGROUND AS SPLASH =====
            Positioned.fill(
              child: Container(
                color: const Color.fromARGB(255, 0, 98, 245),
              ),
            ),

            // ===== LOGO (NO BLUR, JUST SOFT OPACITY) =====
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    "assets/logo.png",
                    width: MediaQuery.of(context).size.width * 1.0,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ===== Bottom sheet (animated) =====
            Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _sheetFade,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(44),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.88),
                          Colors.blueGrey.shade50.withOpacity(0.90),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // small down arrow bubble
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: mycolors.Primary,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Title
                          Text(
                            mytitle.loginTitle.toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withOpacity(0.85),
                                ),
                          ),

                          const SizedBox(height: 16),

                          // IC
                          TextFormField(
                            controller: _icController,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.85),
                              fontSize: mysizes.fontSm,
                            ),
                            decoration: _pillDecoration(
                              hint: mytitle.icno,
                              suffix: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.black.withOpacity(0.55),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _pwController,
                            obscureText: _hidePassword,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.85),
                              fontSize: mysizes.fontSm,
                            ),
                            decoration: _pillDecoration(
                              hint: mytitle.password,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _hidePassword = !_hidePassword),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Login button (blue)
                          SizedBox(
                            width: size.width * 0.35,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomePage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mycolors.Primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // ✅ Biometric button (only if enabled)
                          if (showBiometricButton) ...[
                            const SizedBox(height: 10),
                            IconButton(
                              onPressed: _bioLoading ? null : _biometricLogin,
                              icon: _bioLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.fingerprint),
                              iconSize: 34,
                              color: mycolors.Primary,
                              tooltip: 'Login with biometrics',
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.65),
                                  fontSize: mysizes.fontSm,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                                  );
                                },
                                child: Text(
                                  "Sign UP!",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.85),
                                    fontSize: mysizes.fontSm,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ✅ Small helper text if device supports but user didn’t enable yet
                          if (_bioSupported && !_bioEnabled) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Enable Biometric Login from Settings to use fingerprint / Face ID.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
