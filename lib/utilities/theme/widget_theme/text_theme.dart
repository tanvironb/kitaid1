import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';

class myTextTheme {

  myTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge:TextStyle().copyWith(fontSize: 32.0, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)) ,
    headlineMedium:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,
    headlineSmall:const TextStyle().copyWith(fontSize: 18.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,

    titleLarge: const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary),
    titleMedium:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,
    titleSmall:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,

    bodyLarge:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,
    bodyMedium:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,
    bodySmall:const TextStyle().copyWith(fontSize: 24.0, fontWeight: FontWeight.w600, color: mycolors.textPrimary) ,

     labelLarge: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.normal, color: mycolors.textPrimary) ,
     labelMedium: const TextStyle().copyWith(fontSize: 12.0, fontWeight: FontWeight.normal, color: mycolors.textPrimary.withValues(alpha: 0.5)) ,


  );
}