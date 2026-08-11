import 'package:flutter/material.dart';

abstract final class StoreVisualTokens {
  static const fontFamily = 'Fredoka';

  static const purple = Color(0xFF7446B8);
  static const purpleDark = Color(0xFF3A2252);
  static const purpleLight = Color(0xFFD9BDF0);
  static const lavender = Color(0xFFF1E7FA);
  static const lavenderStrong = Color(0xFFC89FE8);
  static const storeBackdrop = Color(0xFFC39DDB);
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

  static const panelShadow = BoxShadow(
    color: Color(0x50502B6F),
    blurRadius: 12,
    offset: Offset(0, 7),
  );

  static const cardShadow = BoxShadow(
    color: Color(0x305B357E),
    blurRadius: 9,
    offset: Offset(0, 4),
  );

  static const tabShadow = BoxShadow(
    color: Color(0x40502B6F),
    blurRadius: 7,
    offset: Offset(0, 4),
  );

  static const priceButtonShadow = BoxShadow(
    color: Color(0x42A06510),
    blurRadius: 5,
    offset: Offset(0, 3),
  );

  static const statusButtonShadow = BoxShadow(
    color: Color(0x403A2252),
    blurRadius: 5,
    offset: Offset(0, 3),
  );

  static const contactShadow = BoxShadow(
    color: Color(0x32000000),
    blurRadius: 12,
    spreadRadius: 1,
    offset: Offset(0, 3),
  );

  static const textShadow = Shadow(
    color: Color(0x663A2252),
    blurRadius: 1,
    offset: Offset(0, 1.5),
  );
}
