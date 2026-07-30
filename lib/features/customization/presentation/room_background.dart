import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';

class RoomBackground extends PositionComponent with HasGameReference {
  RoomBackground({required this.theme}) : super(priority: -100);

  ThemeOption theme;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await _loadSprite(theme);
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color(theme.backgroundColorValue),
    );
    _sprite?.render(canvas, size: size);
  }

  Future<void> setTheme(ThemeOption theme) async {
    if (theme.id == this.theme.id) {
      return;
    }

    final nextSprite = await _loadSprite(theme);
    this.theme = theme;
    _sprite = nextSprite;
  }

  Future<Sprite?> _loadSprite(ThemeOption theme) async {
    final assetPath = theme.backgroundAssetPath;
    return assetPath == null ? null : Sprite.load(assetPath);
  }
}
