import 'package:flutter/material.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';
import 'package:kitaid1/features/chatbot/chatbot_page.dart';
import 'package:kitaid1/features/notifications/notification_page.dart';
import 'package:kitaid1/features/services/services_page.dart';
import 'package:kitaid1/features/settings/change_password_page.dart';
import 'package:kitaid1/features/settings/privacy_policy_page.dart';
import 'package:kitaid1/features/settings/change_password_page.dart';
import 'package:kitaid1/features/settings/delete_account_page.dart';

import 'package:kitaid1/features/settings/privacy_policy_page.dart';

import 'package:kitaid1/features/settings/settings_page.dart';
import 'package:kitaid1/splashscreen.dart';
import 'package:kitaid1/utilities/theme/theme.dart';

class kitaid extends StatelessWidget {
  const kitaid({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitaID',
      theme: mytheme.LightTheme,
      home: const SettingsPage(),

      routes: {
        '/home': (_) => const HomePage(),
        '/chatbot': (_) => const ChatBotPage(),        
        '/privacy-policy': (_) => const PrivacyPolicyPage(),
        '/services': (_) => const ServicesPage(),
        '/notifications': (_) => const NotificationPage(),
        '/settings': (_) => const SettingsPage(),
        '/change-password': (_) => const ChangePasswordPage(),
        '/delete-account': (_) => const DeleteAccountPage(),
         '/privacy': (_) => const PrivacyPolicyPage(),
          '/login': (_) => const LoginScreen(),
        
      },
    );
  }
}

