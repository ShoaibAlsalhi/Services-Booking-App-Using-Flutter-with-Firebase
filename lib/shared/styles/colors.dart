import 'dart:ui';

import 'package:flutter/cupertino.dart';

const defaultColor = Color(0xFF000000);
const defaultBackgroundColor = Color(0xFFF4EDE3);
const textColor = Color(0xFF143153);
//const ListTileColor = Color(0xFFB0BEC5); // Equivalent to Colors.blueGrey[100]
const ListTileColor = LinearGradient(
  colors: [Color(0xFF88EC9B), Color(0xFF4FF7F7)], // Light green to light blue
  begin: Alignment.topLeft, // Starting point of the gradient
  end: Alignment.bottomRight, // Ending point of the gradient
);

