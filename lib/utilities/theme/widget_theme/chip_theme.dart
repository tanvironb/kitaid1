import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';

class mychiptheme{

  mychiptheme._();

  static ChipThemeData LightChipTheme = ChipThemeData(
    disabledColor: mycolors.disabledprimary,
    labelStyle: const TextStyle(color: mycolors.textPrimary),
    selectedColor: mycolors.Primary,
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
    
  );
}