import 'package:flutter/material.dart';

abstract final class StoreVisualTokens {
  static const purple = Color(0xFF7446B8);
  static const purpleDark = Color(0xFF3A2252);
  static const purpleLight = Color(0xFFD9BDF0);
  static const lavender = Color(0xFFF1E7FA);
  static const lavenderStrong = Color(0xFFC89FE8);
  static const cream = Color(0xFFFFF8EA);
  static const creamStrong = Color(0xFFF8E3C2);
  static const gold = Color(0xFFE1A936);
  static const goldDark = Color(0xFF9A6514);
  static const green = Color(0xFF6FBB45);
  static const danger = Color(0xFFC84F61);

  static const quick = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const backgroundTransition = Duration(milliseconds: 380);

  static const pagePadding = 16.0;
  static const cardRadius = 24.0;
  static const panelRadius = 30.0;

  static const softShadow = BoxShadow(
    color: Color(0x2D5B357E),
    blurRadius: 16,
    offset: Offset(0, 7),
  );

  static const goldShadow = BoxShadow(
    color: Color(0x3DD08C1B),
    blurRadius: 8,
    offset: Offset(0, 3),
  );
}
