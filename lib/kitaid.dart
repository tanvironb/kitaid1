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

class kitaid extends StatelessWidget {
  const kitaid({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitaID',
      theme: mytheme.LightTheme,

      // ✅ AuthGate decides what to show, but Splash will ALWAYS show first (min 2s)
      home: const AuthGate(),

      // ✅ Normal routes (no-args pages)
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

      // ✅ For pages that need arguments (Card Detail)
      onGenerateRoute: (settings) {
        if (settings.name == '/card-detail') {
          final args = (settings.arguments as Map<String, dynamic>?);

          // Fallback safety (in case someone navigates without args)
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

/// ✅ AuthGate decides which screen to show based on Firebase session.
/// ✅ Splash ALWAYS shows first for at least 2 seconds
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // ✅ Keep splash visible for minimum 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ✅ ALWAYS show splash first (for 2 seconds)
        if (_showSplash) {
          return const Splashscreen();
        }

        // ✅ After splash ends, go to the right page
        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginScreen();
      },
    );
  }
}
