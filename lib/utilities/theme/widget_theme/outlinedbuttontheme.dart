import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class myoutlinedButtonTheme{

  myoutlinedButtonTheme._();

  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: mycolors.textPrimary,
      side: const BorderSide(color: mycolors.borderprimary),
      textStyle: const TextStyle(fontSize: 16, color: mycolors.textPrimary, fontWeight: FontWeight.normal),
      padding: const EdgeInsets.symmetric(vertical: mysizes.btnheight, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(mysizes.borderRadiusLg)),
    )
  );
}