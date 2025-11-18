import 'package:flutter/material.dart';
import 'package:kitaid1/features/authentication/screen/homepage/home_page.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';
import 'package:kitaid1/features/authentication/screen/register/signup_otp_page.dart';
import 'package:kitaid1/features/authentication/screen/register/signup_page.dart';
import 'package:kitaid1/features/notifications/notification_page.dart';
import 'package:kitaid1/features/services/services_page.dart';
import 'package:kitaid1/features/settings/privacy_policy_page.dart';
import 'package:kitaid1/features/settings/settings_page.dart';
import 'package:kitaid1/utilities/theme/theme.dart';

class kitaid extends StatelessWidget {
  const kitaid({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',

      // light theme
      theme: mytheme.LightTheme,
      //home: const SignUpOtpPage(phoneNumber: '', signupPayload: {},));
      home: const PrivacyPolicyPage());
  }
}

// void nextpage(){
//   var get;
//   get.offAll(()=> loginScreen());

// }