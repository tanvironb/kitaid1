import 'package:flutter/material.dart';

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
      home: const Splashscreen(),

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
              imageUrl: imageUrl, // ✅ only if your CardDetailPage supports it
            ),
          );
        }

        return null;
      },
    );
  }
}
