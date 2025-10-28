import 'package:flutter/material.dart';
import 'package:kitaid1/main.dart';

class Splashscreen extends StatefulWidget{
  const Splashscreen({Key? key}) :super(key: key);
  

  @override
  _SplashscreenState createState() => _SplashscreenState();
  }
  class _SplashscreenState extends State<Splashscreen>{
    @override
  void initState() {
   _goHome();
    super.initState();
  }
  _goHome()async{
    await Future.delayed(const Duration(milliseconds: 5000),(){});
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Scaffold()));
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
  
  class AkTest {
 
  }
