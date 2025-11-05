import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class myelevatedButton{

  myelevatedButton._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: mycolors.textPrimary,
      backgroundColor: mycolors.btnSecondary,
      disabledForegroundColor: mycolors.disabledprimary,
      side: const BorderSide(color: mycolors.bordersecondary, width: 2),
      padding: const EdgeInsets.symmetric(vertical: mysizes.btnheight,),
      textStyle: const TextStyle(fontSize: 12, color: mycolors.textPrimary, ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(mysizes.borderRadiusLg)),
      // maximumSize: Size(200, 100),
    )
  );
}