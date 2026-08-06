import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';

class StoreHostScreen extends StatelessWidget {
  const StoreHostScreen({required this.controller, super.key});

  final StoreController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Theme(
          data: _themeFrom(controller.selectedTheme),
          child: StoreScreen(controller: controller),
        );
      },
    );
  }

  ThemeData _themeFrom(ThemeOption option) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(option.accentColorValue),
        brightness: option.id == 'techno'
            ? Brightness.dark
            : Brightness.light,
      ),
      scaffoldBackgroundColor: Color(option.backgroundColorValue),
      cardColor: Color(option.surfaceColorValue),
    );
  }
}
