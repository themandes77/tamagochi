import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/customization/domain/pet_skin.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

class PetAvatarComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  PetAvatarComponent({
    required this.controller,
    required this.storeController,
    this.onPetTap,
    this.onCleaningContactStarted,
    this.onCleaningContactStopped,
    this.onCleaningGestureEnded,
    this.isCleaningToolSelected,
    this.isCleaningActive,
  }) : super(anchor: Anchor.center);

  final PetController controller;
  final StoreController storeController;
  final VoidCallback? onPetTap;
  final bool Function()? onCleaningContactStarted;
  final VoidCallback? onCleaningContactStopped;
  final Future<void> Function()? onCleaningGestureEnded;
  final bool Function()? isCleaningToolSelected;
  final bool Function()? isCleaningActive;

  Sprite? _petSprite;
  Sprite? _soapSprite;
  Vector2 _canvasSize = Vector2.zero();
  Vector2? _soapPosition;
  bool _dragGestureActive = false;
  int? _activePointerId;
  bool _contactAccepted = false;
  int _visualLoadGeneration = 0;
  String? _loadedSkinId;

  bool get supportsCleaningGesture =>
      onCleaningContactStarted != null &&
      onCleaningContactStopped != null &&
      onCleaningGestureEnded != null &&
      isCleaningToolSelected != null &&
      isCleaningActive != null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    storeController.addListener(_onStoreChanged);
    if (supportsCleaningGesture) {
      _soapSprite = await Sprite.load('soap.png');
    }
    await _loadSelectedSkin();
    final currentGame = findGame();
    if (currentGame != null) {
      _layoutFor(_canvasSize.isZero() ? currentGame.size : _canvasSize);
    }
  }

  @override
  void onRemove() {
    storeController.removeListener(_onStoreChanged);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _canvasSize = canvasSize.clone();
    _layoutFor(canvasSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dragGestureActive &&
        (!(isCleaningToolSelected?.call() ?? false) ||
            (_contactAccepted && !(isCleaningActive?.call() ?? false)))) {
      _contactAccepted = false;
      _soapPosition = null;
    }
  }

  @override
  void render(Canvas canvas) {
    _petSprite?.render(canvas, size: size);

    final soapSprite = _soapSprite;
    final soapPosition = _soapPosition;
    if (soapSprite != null && soapPosition != null) {
      final soapSize = _soapVisualSize();
      soapSprite.render(
        canvas,
        position: soapPosition - Vector2.all(soapSize / 2),
        size: Vector2.all(soapSize),
      );
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (size.isZero()) {
      return false;
    }
    final left = width * 0.10;
    final top = height * 0.08;
    final right = width * 0.90;
    final bottom = height * 0.94;
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onPetTap?.call();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!supportsCleaningGesture ||
        !(isCleaningToolSelected?.call() ?? false) ||
        _activePointerId != null) {
      return;
    }

    _activePointerId = event.pointerId;
    _dragGestureActive = true;
    _contactAccepted = onCleaningContactStarted!.call();
    _soapPosition = _contactAccepted ? event.localPosition.clone() : null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragGestureActive || event.pointerId != _activePointerId) {
      return;
    }

    if (!(isCleaningToolSelected?.call() ?? false)) {
      _stopCurrentContact();
      return;
    }

    final localPosition = event.localEndPosition;
    if (containsLocalPoint(localPosition)) {
      if (!_contactAccepted) {
        _contactAccepted = onCleaningContactStarted!.call();
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

  void _stopCurrentContact() {
    if (_contactAccepted) {
      onCleaningContactStopped?.call();
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
    final callback = onCleaningGestureEnded;
    if (callback != null) {
      unawaited(callback());
    }
  }

  void _onStoreChanged() {
    final selectedId = storeController.selectedSkin.id;
    if (_loadedSkinId != selectedId) {
      unawaited(_loadSelectedSkin());
    }
  }

  Future<void> _loadSelectedSkin() async {
    final skin = storeController.selectedSkin;
    final generation = ++_visualLoadGeneration;
    final data = await rootBundle.load(skin.spriteSheetAsset);
    final codec = await instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final frame = await codec.getNextFrame();
    codec.dispose();

    if (generation != _visualLoadGeneration || isRemoving) {
      frame.image.dispose();
      return;
    }

    _loadedSkinId = skin.id;
    _petSprite = Sprite(
      frame.image,
      srcPosition: Vector2(0, skin.spriteRow * PetSkin.frameHeight),
      srcSize: Vector2(PetSkin.frameWidth, PetSkin.frameHeight),
    );
    final currentGame = findGame();
    if (currentGame != null) {
      _layoutFor(_canvasSize.isZero() ? currentGame.size : _canvasSize);
    }
  }

  void _layoutFor(Vector2 canvasSize) {
    if (canvasSize.isZero()) {
      return;
    }
    final maxWidth = canvasSize.x * 0.64;
    final maxHeight = canvasSize.y * 0.76;
    var targetWidth = maxWidth;
    var targetHeight = targetWidth / (PetSkin.frameWidth / PetSkin.frameHeight);
    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = targetHeight * (PetSkin.frameWidth / PetSkin.frameHeight);
    }
    size = Vector2(targetWidth, targetHeight);
    position = canvasSize / 2;
  }

  double _soapVisualSize() {
    return (size.x * 0.22).clamp(38.0, 76.0).toDouble();
  }
}
