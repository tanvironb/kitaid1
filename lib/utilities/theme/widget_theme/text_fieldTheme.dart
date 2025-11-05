import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class myinputdecorationbutton{

  myinputdecorationbutton._();

  static InputDecorationTheme lightInputdecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    
    prefixIconColor: mycolors.borderprimary,
    suffixIconColor: mycolors.borderprimary ,

    labelStyle: const TextStyle().copyWith(fontSize: mysizes.fontSm, color: mycolors.textPrimary ),
    hintStyle: const TextStyle().copyWith(fontSize: mysizes.fontSm, color: mycolors.textPrimary ),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: const TextStyle().copyWith(color: mycolors.textPrimary.withValues(alpha:200 )) ,
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
      borderSide: const BorderSide(width: 2, color: mycolors.borderprimary),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
      borderSide: const BorderSide(width: 2, color: mycolors.borderprimary),
      
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
      borderSide: const BorderSide(width: 1, color: mycolors.textPrimary),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
      borderSide: const BorderSide(width: 1, color: mycolors.warningprinmary),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
      borderSide: const BorderSide(width: 1, color: mycolors.warningprinmary),
    ),
  );
}