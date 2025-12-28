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

      // ✅ AuthGate decides what to show after splash + biometric gate
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

/// ✅ Splash ALWAYS shows first (4 seconds)
/// ✅ After splash:
/// - If NOT logged in -> Login
/// - If logged in & biometric enabled -> ask biometric then Home
/// - If biometric fails -> sign out -> Login
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  // ✅ prevent multiple biometric prompts
  bool _bioCheckedThisSession = false;

  // ✅ UI state for biometric gating
  bool _bioGateLoading = false;
  bool _bioGatePassed = false;

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

    setState(() => _bioGateLoading = true);

    try {
      final enabled = await bio.isEnabled();
      final supported = await bio.isDeviceSupported();

      if (enabled && supported) {
        final ok = await bio.authenticate(reason: 'Unlock KitaID');

        if (!mounted) return;

        if (ok) {
          setState(() {
            _bioGatePassed = true;
            _bioGateLoading = false;
          });
        } else {
          // ❌ fail -> sign out -> go login
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() {
            _bioGatePassed = false;
            _bioGateLoading = false;
          });
        }
      } else {
        // biometric OFF -> allow straight to home
        if (!mounted) return;
        setState(() {
          _bioGatePassed = true;
          _bioGateLoading = false;
        });
      }
    } catch (_) {
      // if anything weird happens, fallback to login (safe)
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _bioGatePassed = false;
        _bioGateLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ✅ ALWAYS show splash first
        if (_showSplash) {
          return const Splashscreen();
        }

        // ✅ Not logged in -> Login
        if (!snapshot.hasData) {
          // reset biometric state for next login
          _bioCheckedThisSession = false;
          _bioGateLoading = false;
          _bioGatePassed = false;
          return const LoginScreen();
        }

        // ✅ Logged in -> run biometric gate once
        if (!_bioCheckedThisSession && !_bioGateLoading) {
          // start biometric gate (without blocking build)
          Future.microtask(_runBiometricGate);
        }

        // show loading while gating (nice UX)
        if (_bioGateLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ If biometric gate passed -> Home
        if (_bioGatePassed) {
          return const HomePage();
        }

        // ❌ Gate failed -> Login
        return const LoginScreen();
      },
    );
  }
}
