import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';

/// Slot visual reutilizable para alimentos.
///
/// El layout final no depende del arte: cuando existan assets aprobados basta
/// con asignar [FoodItem.assetPath]. Hasta entonces se usa un placeholder de
/// sistema distinto por alimento para que QA pueda reconocerlos sin fijar arte.
class FoodArtwork extends StatelessWidget {
  const FoodArtwork({
    required this.food,
    this.size,
    this.fit = BoxFit.contain,
    super.key,
  });

  final FoodItem food;
  final double? size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath = food.assetPath;
    if (assetPath != null) {
      return SizedBox.square(
        dimension: size,
        child: Image.asset(
          assetPath,
          fit: fit,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      );
    }

    final icon = switch (food.id) {
      'food_1' => Icons.tag_rounded,
      'food_2' => Icons.thumb_up_alt_rounded,
      'food_3' => Icons.cake_rounded,
      _ => Icons.restaurant_rounded,
    };

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9D8F4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF7446B8), width: 1.8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            return Center(
              child: Icon(
                icon,
                size: side * 0.50,
                color: const Color(0xFF7446B8),
              ),
            );
          },
        ),
      ),
    );
  }
}
