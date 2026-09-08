class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.satiety,
    this.assetPath,
  });

  final String id;

  /// Nombre interno para dominio, tests y accesibilidad.
  /// La UI de comida no lo muestra: el arte definitivo será la identidad visual.
  final String name;
  final int price;
  final double satiety;

  /// Asset opcional para cuando el equipo entregue arte definitivo.
  /// Mientras sea null la UI utiliza un placeholder Flutter responsive.
  final String? assetPath;
}

enum FoodPurchaseResult {
  success,
  insufficientFunds,
  inventoryFull,
  itemNotFound,
}
