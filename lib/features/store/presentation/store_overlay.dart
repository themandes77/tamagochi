import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';

class StoreOverlay extends StatelessWidget {
  const StoreOverlay({
    required this.controller,
    required this.onClose,
    this.initialKind = ShopItemKind.outfit,
    super.key,
  });

  final StoreController controller;
  final VoidCallback onClose;
  final ShopItemKind initialKind;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Theme(
          data: storeThemeFrom(controller.selectedTheme),
          child: StoreScreen(
            controller: controller,
            initialKind: initialKind,
            onClose: onClose,
          ),
        );
      },
    );
  }
}
