import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';
import 'package:kitaid1/features/authentication/screen/profile/profile.dart';
import 'package:kitaid1/features/authentication/screen/profile/card_detail_page.dart';
import 'package:kitaid1/features/chatbot/chatbot_page.dart';
import 'package:kitaid1/features/notifications/notification_page.dart';
import 'package:kitaid1/features/services/services_page.dart';
import 'package:kitaid1/features/settings/change_password_page.dart';
import 'package:kitaid1/features/settings/delete_account_page.dart';
import 'package:kitaid1/features/settings/privacy_policy_page.dart';
import 'package:kitaid1/features/settings/settings_page.dart';
import 'package:kitaid1/features/support/faq_page.dart';
import 'package:kitaid1/splashscreen.dart';
import 'package:kitaid1/utilities/theme/theme.dart';
import 'package:kitaid1/features/services/biometric_auth_service.dart';

class kitaid extends StatelessWidget {
  const kitaid({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitaID',
      theme: mytheme.LightTheme,

      // AuthGate decides what to show after splash + biometric gate
      home: const AuthGate(),

      routes: {
        '/home': (_) => const HomePage(),
        '/chatbot': (_) => const ChatBotPage(),
        '/privacy-policy': (_) => const PrivacyPolicyPage(),
        '/services': (_) => const ServicesPage(),
        '/notifications': (_) => const NotificationPage(),
        '/profile': (_) => const ProfilePage(),
        '/change-password': (_) => const ChangePasswordPage(),
        '/delete-account': (_) => const DeleteAccountPage(),
        '/privacy': (_) => const PrivacyPolicyPage(),
        '/login': (_) => const LoginScreen(),
        '/settings': (_) => const SettingsPage(),
        '/faq': (_) => const FaqPage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/card-detail') {
          final args = (settings.arguments as Map<String, dynamic>?);

          final cardId = (args?['cardId'] ?? '').toString();
          final title = (args?['title'] ?? 'Card Details').toString();
          final imageUrl = (args?['imageUrl'] as String?);

          return MaterialPageRoute(
            builder: (_) => CardDetailPage(
              cardTitle: title,
              cardIdLabel: cardId,
              ownerName: (args?['ownerName'] ?? '').toString(),
              ownerDob: (args?['ownerDob'] ?? '').toString(),
              ownerCountry: (args?['ownerCountry'] ?? '').toString(),
              imageUrl: imageUrl,
            ),
          );
        }
        return null;
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  // prevent multiple biometric prompts
  bool _bioCheckedThisSession = false;

  // UI state for biometric gating
  bool _bioGateLoading = false;
  bool _bioGatePassed = false;
  String? _bioError;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<void> _runBiometricGate() async {
    if (_bioCheckedThisSession) return;
    _bioCheckedThisSession = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bio = BiometricAuthService.instance;

    if (!mounted) return;
    setState(() {
      _bioGateLoading = true;
      _bioError = null;
    });

    try {
      final enabled = await bio.isEnabled();
      final supported = await bio.isDeviceSupported();

      // biometric OFF / not supported -> allow straight to home
      if (!enabled || !supported) {
        if (!mounted) return;
        setState(() {
          _bioGatePassed = true;
          _bioGateLoading = false;
        });
        return;
      }

      final ok = await bio.authenticate(reason: 'Unlock KitaID');

      if (!mounted) return;
      setState(() {
        _bioGatePassed = ok;
        _bioGateLoading = false;
        if (!ok) _bioError = 'Biometric authentication was cancelled or failed.';
      });
    } catch (_) {
      // IMPORTANT: do NOT sign out here
      if (!mounted) return;
      setState(() {
        _bioGatePassed = false;
        _bioGateLoading = false;
        _bioError = 'Unable to authenticate with biometrics.';
      });
    }
  }

  void _retryBiometric() {
    setState(() {
      _bioCheckedThisSession = false;
      _bioGateLoading = false;
      _bioGatePassed = false;
      _bioError = null;
    });
  }

  Widget _lockScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 12),
              const Text(
                'KitaID is locked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _bioError ?? 'Please authenticate to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retryBiometric,
                child: const Text('Try again'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  // manual logout only
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Always show splash first
        if (_showSplash) {
          return const Splashscreen();
        }

        // IMPORTANT: wait for Firebase to restore session on cold start
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in -> Login
        if (!snapshot.hasData) {
          // reset biometric state for next login
          _bioCheckedThisSession = false;
          _bioGateLoading = false;
          _bioGatePassed = false;
          _bioError = null;
          return const LoginScreen();
        }

        // Logged in -> run biometric gate once
        if (!_bioCheckedThisSession && !_bioGateLoading && !_bioGatePassed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _runBiometricGate();
          });
        }

        // show loading while gating in progress
        if (_bioGateLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If biometric gate passed -> Home
        if (_bioGatePassed) {
          return const HomePage();
        }

        // Logged in but locked (biometric required and not passed)
        return _lockScreen();
      },
    );
  }
}
