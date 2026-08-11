import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/presentation/room_background.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

/// Escena Flame alojada por el Home Flutter.
///
/// La escena conserva las piezas visuales de Azael (fondo + NTI) y deja fuera
/// deliberadamente su Hud, ToolBar y StoreAccessButton. El estado de la mascota
/// continúa perteneciendo a PetController/HomeController en la capa Flutter.
class HomePetScene extends FlameGame {
  HomePetScene({
    required this.storeController,
    required this.onFoodTap,
    required this.onCleaningContactStarted,
    required this.onCleaningContactStopped,
    required this.onCleaningGestureEnded,
    required this.isFoodToolSelected,
    required this.isCleaningToolSelected,
    required this.isCleaningActive,
    required this.isFullyClean,
  }) : nti = Nti(outfit: storeController.selectedOutfit),
       roomBackground = RoomBackground(theme: storeController.selectedTheme);

  final StoreController storeController;
  final Future<FoodFeedResult> Function() onFoodTap;
  final bool Function() onCleaningContactStarted;
  final VoidCallback onCleaningContactStopped;
  final Future<void> Function() onCleaningGestureEnded;
  final bool Function() isFoodToolSelected;
  final bool Function() isCleaningToolSelected;
  final bool Function() isCleaningActive;
  final bool Function() isFullyClean;

  final Nti nti;
  final RoomBackground roomBackground;
  late final _HomeCareInteractionLayer _careLayer;
  Future<void> _customizationTail = Future<void>.value();

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // No se llama images.loadAllImages(): el arranque solo carga los recursos
    // críticos del Home. La Tienda se precarga después, sin bloquear el Home.
    await add(roomBackground);
    await add(nti);

    _careLayer = _HomeCareInteractionLayer(
      nti: nti,
      onFoodTap: onFoodTap,
      onCleaningContactStarted: onCleaningContactStarted,
      onCleaningContactStopped: onCleaningContactStopped,
      onCleaningGestureEnded: onCleaningGestureEnded,
      isFoodToolSelected: isFoodToolSelected,
      isCleaningToolSelected: isCleaningToolSelected,
      isCleaningActive: isCleaningActive,
      isFullyClean: isFullyClean,
    );
    await add(_careLayer);

    storeController.addListener(_onStoreChanged);
  }

  @override
  void onRemove() {
    storeController.removeListener(_onStoreChanged);
    super.onRemove();
  }

  void _onStoreChanged() {
    _customizationTail = _customizationTail
        .then((_) => _applyCustomization())
        .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'nt_tamagochi.home_pet_scene',
              context: ErrorDescription('al aplicar personalización de NTI'),
            ),
          );
        });
  }

  Future<void> _applyCustomization() async {
    if (!isLoaded || nti.isRemoving || roomBackground.isRemoving) {
      return;
    }

    final outfit = storeController.selectedOutfit;
    final theme = storeController.selectedTheme;

    if (nti.outfit != outfit) {
      await nti.wear(outfit);
    }
    await roomBackground.setTheme(theme);
  }
}

/// Capa de integración propia para conservar los gestos de cuidado existentes
/// sin conectar el ToolBar de Azael ni duplicar el estado Pet dentro de Nti.
class _HomeCareInteractionLayer extends PositionComponent with DragCallbacks, TapCallbacks {
  _HomeCareInteractionLayer({
    required this.nti,
    required this.onFoodTap,
    required this.onCleaningContactStarted,
    required this.onCleaningContactStopped,
    required this.onCleaningGestureEnded,
    required this.isFoodToolSelected,
    required this.isCleaningToolSelected,
    required this.isCleaningActive,
    required this.isFullyClean,
  }) : super(priority: 100);

  final Nti nti;
  final Future<FoodFeedResult> Function() onFoodTap;
  final bool Function() onCleaningContactStarted;
  final VoidCallback onCleaningContactStopped;
  final Future<void> Function() onCleaningGestureEnded;
  final bool Function() isFoodToolSelected;
  final bool Function() isCleaningToolSelected;
  final bool Function() isCleaningActive;
  final bool Function() isFullyClean;

  Sprite? _soapSprite;
  Vector2? _soapPosition;
  bool _dragGestureActive = false;
  int? _activePointerId;
  bool _contactAccepted = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = findGame()!.size;
    _soapSprite = await Sprite.load('soap.png');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    size = canvasSize;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!isFoodToolSelected() && !isCleaningToolSelected()) {
      return false;
    }
    return _containsNtiPoint(point);
  }

  bool _containsNtiPoint(Vector2 point) {
    final scaleX = nti.scale.x.abs();
    final scaleY = nti.scale.y.abs();
    final visualWidth = nti.size.x * scaleX;
    final visualHeight = nti.size.y * scaleY;
    final left = nti.position.x - visualWidth * 0.40;
    final right = nti.position.x + visualWidth * 0.40;
    final top = nti.position.y - visualHeight * 0.42;
    final bottom = nti.position.y + visualHeight * 0.44;

    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isFoodToolSelected()) {
      return false;
    }

    unawaited(_handleFoodTapAndReact());
    return true;
  }

  Future<void> _handleFoodTapAndReact() async {
    try {
      final result = await onFoodTap();
      switch (result.status) {
        case FoodFeedStatus.success:
          nti.react();
          nti.say('¡Qué rico! Ya tengo energía.');
          break;
        case FoodFeedStatus.tooFull:
          nti.react();
          nti.say('¡Ya estoy lleno!');
          break;
        case FoodFeedStatus.outOfStock:
        case FoodFeedStatus.itemNotFound:
        case FoodFeedStatus.blocked:
        case FoodFeedStatus.noSelection:
        case FoodFeedStatus.staleSelection:
          break;
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.home_pet_scene',
          context: ErrorDescription('al consumir una comida'),
        ),
      );
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isCleaningToolSelected() || _activePointerId != null) {
      return;
    }

    _activePointerId = event.pointerId;
    _dragGestureActive = true;
    _contactAccepted = onCleaningContactStarted();
    _soapPosition = _contactAccepted ? event.localPosition.clone() : null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragGestureActive || event.pointerId != _activePointerId) {
      return;
    }

    if (!isCleaningToolSelected()) {
      _stopCurrentContact();
      return;
    }

    final localPosition = event.localEndPosition;
    if (_containsNtiPoint(localPosition)) {
      if (!_contactAccepted) {
        _contactAccepted = onCleaningContactStarted();
      }
      _soapPosition = _contactAccepted ? localPosition.clone() : null;
      return;
    }

    _stopCurrentContact();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDragGesture(event.pointerId);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finishDragGesture(event.pointerId);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dragGestureActive &&
        (!isCleaningToolSelected() ||
            (_contactAccepted && !isCleaningActive()))) {
      _contactAccepted = false;
      _soapPosition = null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sprite = _soapSprite;
    final position = _soapPosition;
    if (sprite == null || position == null) {
      return;
    }

    final soapSize = (nti.size.x * nti.scale.x.abs() * 0.20)
        .clamp(38.0, 76.0)
        .toDouble();
    sprite.render(
      canvas,
      position: position - Vector2.all(soapSize / 2),
      size: Vector2.all(soapSize),
    );
  }

  void _stopCurrentContact() {
    if (_contactAccepted) {
      onCleaningContactStopped();
    }
    _contactAccepted = false;
    _soapPosition = null;
  }

  void _finishDragGesture(int pointerId) {
    if (!_dragGestureActive || pointerId != _activePointerId) {
      return;
    }

    _stopCurrentContact();
    _dragGestureActive = false;
    _activePointerId = null;
    unawaited(_finishCleaningAndReact());
  }

  Future<void> _finishCleaningAndReact() async {
    await onCleaningGestureEnded();
    if (isFullyClean()) {
      nti.react();
      nti.say('¡Gracias! Me siento limpio.');
    }
  }
}
