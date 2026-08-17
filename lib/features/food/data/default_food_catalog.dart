import 'package:flutter_application_1/features/food/domain/food_item.dart';

const defaultFoodCatalog = <FoodItem>[
  FoodItem(
    id: 'food_1',
    name: 'Hashtag',
    price: 1,
    satiety: 1,
  ),
  FoodItem(
    id: 'food_2',
    name: 'Like',
    price: 3,
    satiety: 5,
  ),
  FoodItem(
    id: 'food_3',
    name: 'Pastel aniversario',
    price: 5,
    satiety: 10,
  ),
];

FoodItem? foodItemById(String id) {
  for (final item in defaultFoodCatalog) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}

Map<String, int> emptyFoodInventory() {
  return <String, int>{
    for (final item in defaultFoodCatalog) item.id: 0,
  };
}
