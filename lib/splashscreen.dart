import 'package:flutter/material.dart';
import 'package:kitaid1/features/authentication/screen/login/login.dart';

class Splashscreen extends StatefulWidget{
  const Splashscreen({super.key});
  

  @override
  _SplashscreenState createState() => _SplashscreenState();
  }
  class _SplashscreenState extends State<Splashscreen>{
    @override
  void initState() {
   _goHome();
    super.initState();
  }
  // _goHome()async{
  //   await Future.delayed(const Duration(milliseconds: 5000),(){});
  //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Scaffold()));
  // }
   Future<void> _goHome() async {
    // wait for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    // after 5s, replace splash with LoginScreen
    if (!mounted) return;    // ✅ safety check
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
   @override
   Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 98, 245),
      body: Center(
        child: Image.asset("assets/logo.png"),

      ),
    );
   }
  }
  
  // class AkTest {
 
  // }
