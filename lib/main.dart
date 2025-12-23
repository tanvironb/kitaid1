import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kitaid1/firebase_options.dart';
import 'package:kitaid1/kitaid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 

  print('🔥 Firebase connected: ${Firebase.apps.first.name}');

  runApp(const kitaid());

}

