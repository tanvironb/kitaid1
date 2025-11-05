import 'package:flutter/material.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';
import 'package:kitaid1/features/authentication/screen/register/signup_otp_page.dart';
import 'package:kitaid1/features/authentication/screen/register/signup_page.dart';
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
      home: const SignUpOtpPage(phoneNumber: '', signupPayload: {},));
  }
}

// void nextpage(){
//   var get;
//   get.offAll(()=> loginScreen());

// }