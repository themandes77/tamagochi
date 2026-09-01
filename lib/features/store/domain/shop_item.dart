enum ShopItemKind { outfit, theme, food }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.kind,
    required this.customizationId,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final ShopItemKind kind;
  final String customizationId;
}

enum PurchaseResult { success, alreadyOwned, insufficientFunds, itemNotFound }
