import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/theme/widget_theme/chip_theme.dart';
import 'package:kitaid1/utilities/theme/widget_theme/elevatedbutton.dart';
import 'package:kitaid1/utilities/theme/widget_theme/outlinedbuttontheme.dart';
import 'package:kitaid1/utilities/theme/widget_theme/text_fieldTheme.dart';
import 'package:kitaid1/utilities/theme/widget_theme/text_theme.dart';

class mytheme{

  //private constructor
  // cannot create object
  mytheme._();

//light theme
  static ThemeData LightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: '',
    brightness: Brightness.light,
    primaryColor: mycolors.Primary,
    disabledColor: mycolors.disabledprimary,
    textTheme: myTextTheme.lightTextTheme,
    chipTheme: mychiptheme.LightChipTheme ,
    scaffoldBackgroundColor: mycolors.bgPrimary ,
    //appBarTheme: ,
    //bottomSheetTheme: ,
    elevatedButtonTheme: myelevatedButton.lightElevatedButtonTheme,
    outlinedButtonTheme: myoutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: myinputdecorationbutton.lightInputdecorationTheme,
  ); 



}