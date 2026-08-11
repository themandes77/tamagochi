import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_overlay.dart';

class StoreHostScreen extends StatelessWidget {
  const StoreHostScreen({
    required this.controller,
    this.initialKind = ShopItemKind.outfit,
    super.key,
  });

  final StoreController controller;
  final ShopItemKind initialKind;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: true,
      child: StoreOverlay(
        controller: controller,
        initialKind: initialKind,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
