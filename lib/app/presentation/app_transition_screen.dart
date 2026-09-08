import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_ui_assets.dart';

class AppTransitionScreen extends StatelessWidget {
  const AppTransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF422171),
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(AppUiAssets.transitionInterface),
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
