import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';

import 'package:kitaid1/features/authentication/screen/register/signup_page.dart';
import 'package:kitaid1/features/services/biometric_auth_service.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:kitaid1/utilities/constant/texts.dart';

// ✅ NEW: Forgot Password page
import 'package:kitaid1/features/settings/forgot_password_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _sheetFade;

  bool _hidePassword = true;
  bool _loggingIn = false;

  final _icController = TextEditingController(); // IC/Passport input
  final _pwController = TextEditingController();

  bool _bioSupported = false;
  bool _bioEnabled = false;
  bool _bioLoading = false;

  // ✅ NEW: Face ID / Face Unlock UI switch
  bool _bioIsFace = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
    _loadBiometric();
  }

  /// ✅ Reload biometric status when user returns from background / settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBiometric();
    }
  }

  Future<void> _loadBiometric() async {
    final bio = BiometricAuthService.instance;
    final supported = await bio.isDeviceSupported();
    final enabled = await bio.isEnabled();

    // ✅ NEW: detect face for UI
    final isFace = supported ? await bio.supportsFace() : false;

    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
      _bioIsFace = isFace;
    });
  }

  /// ✅ Same normalization used in signup:
  /// - Trim
  /// - Uppercase
  /// - Keep only A-Z and 0-9
  String _normalizeLoginId(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// ✅ Convert to FirebaseAuth email (must match signup)
  String _idToAuthEmail(String normalizedId) => '$normalizedId@kitaid.my';

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ Load recents from Firestore into RecentServicesStore (persisted)
  Future<void> _loadRecentsAfterLogin(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('recentServices')
        .orderBy('lastOpenedAt', descending: true)
        .limit(10)
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      final name = (data['name'] ?? d.id).toString();
      return ServiceRef(d.id, name);
    }).toList();

    RecentServicesStore.instance.setRecents(list);
  }

  Future<void> _login() async {
    if (_loggingIn) return;

    final rawId = _icController.text;
    final pw = _pwController.text;

    if (rawId.trim().isEmpty || pw.isEmpty) {
      _snack('Please enter IC/Passport and password.');
      return;
    }

    final normalizedId = _normalizeLoginId(rawId);

    if (normalizedId.length < 6) {
      _snack('Please enter a valid IC/Passport number.');
      return;
    }

    final authEmail = _idToAuthEmail(normalizedId);

    setState(() => _loggingIn = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: authEmail,
        password: pw,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'Login failed.');
      }

      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        _snack('User profile not found. Please sign up again.');
        return;
      }

      final data = doc.data() ?? {};

      final storedNormalized = _normalizeLoginId(
        (data['LoginIdNormalized'] ?? data['LoginId'] ?? '').toString(),
      );

      final legacyIc = _normalizeLoginId((data['IC No'] ?? '').toString());
      final legacyPassport =
          _normalizeLoginId((data['Passport No'] ?? '').toString());

      final match = storedNormalized.isNotEmpty
          ? (storedNormalized == normalizedId)
          : (legacyIc == normalizedId || legacyPassport == normalizedId);

      if (!match) {
        await FirebaseAuth.instance.signOut();
        _snack('IC/Passport number does not match this account.');
        return;
      }

      await _loadRecentsAfterLogin(uid);
      await _loadBiometric();

      if (!mounted) return;
      setState(() => _loggingIn = false);

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loggingIn = false);

      final msg = switch (e.code) {
        'user-not-found' =>
          'No account found for this IC/Passport. Please sign up first.',
        'wrong-password' => 'Wrong password. Try again.',
        'invalid-email' => 'Invalid IC/Passport format.',
        'invalid-credential' => 'Wrong IC/Passport or password.',
        _ => e.message ?? 'Login failed. Try again.',
      };

      _snack(msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingIn = false);
      _snack('Error: $e');
    }
  }

  Future<void> _biometricLogin() async {
    if (_bioLoading) return;

    final bio = BiometricAuthService.instance;

    final supported = await bio.isDeviceSupported();
    final enabled = await bio.isEnabled();
    final isFace = supported ? await bio.supportsFace() : false;

    if (!supported) {
      if (!mounted) return;
      _snack('Biometric is not supported on this device.');
      return;
    }

    if (!enabled) {
      if (!mounted) return;
      _snack('Biometric login is not enabled.');
      return;
    }

    setState(() {
      _bioLoading = true;
      _bioIsFace = isFace;
    });

    final ok = await bio.authenticate(
      reason: isFace ? 'Login with Face ID' : 'Login with fingerprint',
    );

    if (!mounted) return;
    setState(() => _bioLoading = false);

    if (!ok) {
      _snack('Biometric verification failed.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('No saved session. Please login with IC/Passport + password first.');
      return;
    }

    await _loadRecentsAfterLogin(user.uid);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    final bioIcon = _bioIsFace ? Icons.face : Icons.fingerprint;
    final bioTooltip =
        _bioIsFace ? 'Login with Face ID' : 'Login with fingerprint';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: const Color.fromARGB(255, 0, 98, 245)),
            ),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(44)),
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
                                onPressed: () =>
                                    FocusScope.of(context).unfocus(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mytitle.loginTitle.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withOpacity(0.85),
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _icController,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.85),
                              fontSize: mysizes.fontSm,
                            ),
                            decoration: _pillDecoration(
                              hint: 'IC / Passport No',
                              suffix: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.black.withOpacity(0.55),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
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
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ),
                          ),

                          // ✅ NEW: Forgot password link (no other UI changes)
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: size.width * 0.35,
                            child: ElevatedButton(
                              onPressed: _loggingIn ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mycolors.Primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: _loggingIn
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: mysizes.fontSm,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          if (showBiometricButton) ...[
                            const SizedBox(height: 10),
                            IconButton(
                              onPressed: _bioLoading ? null : _biometricLogin,
                              icon: _bioLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(bioIcon),
                              iconSize: 34,
                              color: mycolors.Primary,
                              tooltip: bioTooltip,
                            ),
                          ],
                          const SizedBox(height: 16),
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
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpPage()),
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
                          if (_bioSupported && !_bioEnabled) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Enable Face ID / Biometric Login from Settings to use Face ID or fingerprint.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontSize: 11,
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
