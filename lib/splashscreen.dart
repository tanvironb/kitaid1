import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 98, 245),
      body: Center(
        child: Image(
          image: AssetImage("assets/logo.png"),
          width: 160,
        ),
      ),
    );
  }
}
