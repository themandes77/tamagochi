import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();
    Flame.device.fullScreen();

    NtiTamagochi game = NtiTamagochi();
    runApp(GameWidget(game: kDebugMode ? NtiTamagochi() : game));
}
