import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/gui.dart';

enum PlayerState { idle }

class Nti extends PositionComponent with TapCallbacks {
    final double stepTime = 0.05;
    double hunger;
    double cleanliness;
    double energy;

    double decayRate = 0.2;
    ToolBar? toolBar;

    Nti({
        this.hunger = 10,
        this.cleanliness = 10,
        this.energy = 10,
    });

    void feed() {
        hunger = (hunger + 3).clamp(0, 10);
    }
    void wash() {
        cleanliness = (cleanliness + 3).clamp(0, 10);
    }

    void tick() {
        hunger = (hunger - decayRate).clamp(0, 10);
        cleanliness = (cleanliness - decayRate).clamp(0, 10);
        energy = (energy - decayRate).clamp(0, 10);
    }
    
    @override
    FutureOr<void> onLoad() async {
        final sprite = await Sprite.load("nti.png");
        final component = SpriteComponent(
                sprite: sprite,
                size: Vector2(224, 280),
                anchor: Anchor.center,
                position: findGame()!.size/2,
                );
        add(component);

        return super.onLoad();
    }

    @override
    void render(Canvas canvas) {
        super.render(canvas);
        canvas.drawRect(
            Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
            Paint()
                ..color = Colors.red
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
        );
    }

    @override
    bool onTapDown(TapDownEvent event) {
        if (toolBar == null) return false;
        switch (toolBar!.selected) {
            case Tool.soap:
                wash();
                break;
            case Tool.food:
                feed();
                break;
            case Tool.none:
                break;
        }
        return true;
    }
}
