class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.satiety,
    this.assetPath,
  });

  final String id;
  final String name;
  final int price;
  final double satiety;

  /// Asset opcional para cuando el equipo entregue arte definitivo.
  /// Mientras sea null la UI utiliza un placeholder Flutter.
  final String? assetPath;
}

enum FoodPurchaseResult {
  success,
  insufficientFunds,
  itemNotFound,
}
