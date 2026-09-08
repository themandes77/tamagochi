import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';
import 'package:flutter_application_1/features/food/presentation/food_artwork.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/integration/audio/game_sound_effects.dart';

class FoodPurchaseDialog extends StatefulWidget {
  const FoodPurchaseDialog({required this.storeController, super.key});

  final StoreController storeController;

  @override
  State<FoodPurchaseDialog> createState() => _FoodPurchaseDialogState();
}

class _FoodPurchaseDialogState extends State<FoodPurchaseDialog> {
  Timer? _pulseTimer;
  String? _pulsingFoodId;
  String? _errorMessage;

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _buy(FoodItem food) async {
    final result = await widget.storeController.buyFood(food.id);
    if (!mounted) {
      return;
    }

    switch (result) {
      case FoodPurchaseResult.success:
        _pulseTimer?.cancel();
        setState(() {
          _pulsingFoodId = food.id;
          _errorMessage = null;
        });
        _pulseTimer = Timer(const Duration(milliseconds: 180), () {
          if (mounted && _pulsingFoodId == food.id) {
            setState(() => _pulsingFoodId = null);
          }
        });
        break;
      case FoodPurchaseResult.insufficientFunds:
        setState(() => _errorMessage = 'No tienes suficientes monedas.');
        break;
      case FoodPurchaseResult.itemNotFound:
        setState(() => _errorMessage = 'La comida ya no está disponible.');
        break;
      case FoodPurchaseResult.inventoryFull:
        // El botón ya queda deshabilitado en 99. Este caso sólo cubre taps
        // rápidos que hayan quedado en cola justo antes de alcanzar el límite.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = math.min(screenHeight * 0.82, 640.0);

    return Dialog(
      key: const ValueKey('food_purchase_dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: maxDialogHeight),
        child: Material(
          color: const Color(0xFFFFF8FC),
          elevation: 18,
          shadowColor: const Color(0x663A2252),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  key: const ValueKey('food_purchase_header'),
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Comprar comida',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3A2252),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('food_purchase_close'),
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: AnimatedBuilder(
                    animation: widget.storeController,
                    builder: (context, _) {
                      final foods = widget.storeController.foodCatalog;

                      return SingleChildScrollView(
                        key: const ValueKey('food_purchase_list'),
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (
                              var index = 0;
                              index < foods.length;
                              index++
                            ) ...<Widget>[
                              if (index > 0) const SizedBox(height: 10),
                              _FoodPurchaseCard(
                                food: foods[index],
                                quantity: widget.storeController.foodQuantity(
                                  foods[index].id,
                                ),
                                maxQuantity:
                                    StoreController.maxFoodQuantityPerItem,
                                pulsing: _pulsingFoodId == foods[index].id,
                                onBuy: () => unawaited(_buy(foods[index])),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: _errorMessage == null
                      ? const SizedBox(height: 4)
                      : Padding(
                          key: ValueKey(_errorMessage),
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9A3D57),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodPurchaseCard extends StatelessWidget {
  const _FoodPurchaseCard({
    required this.food,
    required this.quantity,
    required this.maxQuantity,
    required this.pulsing,
    required this.onBuy,
  });

  final FoodItem food;
  final int quantity;
  final int maxQuantity;
  final bool pulsing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final full = quantity >= maxQuantity;

    return Semantics(
      container: true,
      label: '${food.name}, $quantity de $maxQuantity unidades',
      child: AnimatedScale(
        scale: pulsing ? 1.045 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        child: Container(
          key: ValueKey('food_purchase_card_${food.id}'),
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x557446B8), width: 1.4),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x1D3A2252),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final artSize = math
                  .min(constraints.maxWidth * 0.72, 96.0)
                  .clamp(54.0, 96.0)
                  .toDouble();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FoodArtwork(food: food, size: artSize),
                  const SizedBox(height: 7),
                  Text(
                    'x$quantity',
                    key: ValueKey('food_purchase_quantity_${food.id}'),
                    style: const TextStyle(
                      color: Color(0xFF3A2252),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: FilledButton(
                      key: ValueKey('food_purchase_buy_${food.id}'),
                      onPressed: full
                          ? null
                          : () {
                              GameSoundEffects.playButton();
                              onBuy();
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: const Color(0xFFFFC84E),
                        foregroundColor: const Color(0xFF3A2252),
                        disabledBackgroundColor: const Color(0xFFE4D8CC),
                        disabledForegroundColor: const Color(0xFF8A7B86),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: full
                                ? const Color(0x558A7B86)
                                : const Color(0xFFDB9E23),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: full
                          ? const Text(
                              '99',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${food.price}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  'assets/images/ui/coin_star_v1.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  excludeFromSemantics: true,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
