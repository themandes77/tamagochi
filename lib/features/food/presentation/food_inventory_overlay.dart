import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';
import 'package:flutter_application_1/features/food/presentation/food_artwork.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

class FoodInventoryOverlay extends StatelessWidget {
  const FoodInventoryOverlay({
    required this.storeController,
    required this.selectedFoodId,
    required this.onFoodSelected,
    required this.onOpenPurchase,
    required this.onClose,
    super.key,
  });

  final StoreController storeController;
  final String? selectedFoodId;
  final ValueChanged<String> onFoodSelected;
  final VoidCallback onOpenPurchase;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('food_inventory_barrier'),
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Material(
                    key: const ValueKey('food_inventory_panel'),
                    color: const Color(0xEFFFF8FC),
                    elevation: 14,
                    shadowColor: const Color(0x553A2252),
                    borderRadius: BorderRadius.circular(26),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Alimentar',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF3A2252),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('food_inventory_close'),
                                tooltip: 'Cerrar inventario',
                                onPressed: onClose,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          AnimatedBuilder(
                            animation: storeController,
                            builder: (context, _) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final entries = <Widget>[
                                    _FoodPurchaseShortcut(
                                      onTap: onOpenPurchase,
                                    ),
                                    for (final food
                                        in storeController.foodCatalog)
                                      _FoodInventoryTile(
                                        food: food,
                                        quantity: storeController.foodQuantity(
                                          food.id,
                                        ),
                                        selected: selectedFoodId == food.id,
                                        onTap: onFoodSelected,
                                      ),
                                  ];
                                  final columns = constraints.maxWidth < 270
                                      ? 2
                                      : 4;
                                  const gap = 6.0;
                                  final itemWidth = math.max(
                                    0.0,
                                    (constraints.maxWidth -
                                            gap * (columns - 1)) /
                                        columns,
                                  );

                                  return Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: <Widget>[
                                      for (final entry in entries)
                                        SizedBox(
                                          width: itemWidth,
                                          child: entry,
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: storeController,
                            builder: (context, _) {
                              final hasFood = storeController.foodCatalog.any(
                                (food) =>
                                    storeController.foodQuantity(food.id) > 0,
                              );
                              if (hasFood) {
                                return const SizedBox(height: 4);
                              }
                              return const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'Usa + para comprar comida.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF77559A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodPurchaseShortcut extends StatelessWidget {
  const _FoodPurchaseShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Comprar comida',
      child: AspectRatio(
        aspectRatio: 0.92,
        child: InkWell(
          key: const ValueKey('food_inventory_purchase_shortcut'),
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDCC5EF).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF7446B8), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                size: 34,
                color: Color(0xFF7446B8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodInventoryTile extends StatelessWidget {
  const _FoodInventoryTile({
    required this.food,
    required this.quantity,
    required this.selected,
    required this.onTap,
  });

  final FoodItem food;
  final int quantity;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = quantity > 0;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '${food.name}, $quantity disponibles',
      child: AspectRatio(
        aspectRatio: 0.92,
        child: InkWell(
          key: ValueKey('food_inventory_${food.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? () => onTap(food.id) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE8D5F7)
                  : const Color(
                      0xFFF9EEF7,
                    ).withValues(alpha: enabled ? 0.90 : 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF7446B8)
                    : const Color(0x557446B8),
                width: selected ? 2 : 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final artSize = math
                    .min(
                      constraints.maxWidth * 0.68,
                      constraints.maxHeight * 0.62,
                    )
                    .clamp(28.0, 62.0)
                    .toDouble();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Opacity(
                      opacity: enabled ? 1 : 0.48,
                      child: FoodArtwork(food: food, size: artSize),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'x$quantity',
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFF3A2252)
                            : const Color(0x883A2252),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
