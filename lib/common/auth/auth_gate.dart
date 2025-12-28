import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kitaid1/features/services/biometric_auth_service.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  Widget? _page;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final user = FirebaseAuth.instance.currentUser;

    // ❌ No session → Login
    if (user == null) {
      _page = const LoginScreen();
      _loading = false;
      if (mounted) setState(() {});
      return;
    }

    final bio = BiometricAuthService.instance;
    final enabled = await bio.isEnabled();
    final supported = await bio.isDeviceSupported();

    // ✅ Session exists + biometric enabled → gate with biometric
    if (enabled && supported) {
      final ok = await bio.authenticate(reason: 'Unlock KitaID');
      if (!ok) {
        // If biometric fails, fallback to login
        await FirebaseAuth.instance.signOut();
        _page = const LoginScreen();
      } else {
        _page = const HomePage();
      }
    } else {
      // Session exists but biometric OFF
      _page = const HomePage();
    }

    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _page!;
  }
}
