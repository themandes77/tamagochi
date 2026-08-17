import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
import 'package:flutter_application_1/features/food/presentation/food_inventory_overlay.dart';
import 'package:flutter_application_1/features/food/presentation/food_purchase_dialog.dart';
import 'package:flutter_application_1/features/home/application/care_tool.dart';
import 'package:flutter_application_1/features/home/application/home_controller.dart';
import 'package:flutter_application_1/features/home/application/home_notice.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_action_button.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_top_bar.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/need_status_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pause_overlay.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pet_message_bubble.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/presentation/home_pet_scene.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/theme/app_ui_assets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.homeController,
    required this.petController,
    required this.storeController,
    required this.preferencesController,
    required this.onExitRequested,
    this.onPlayRequested,
    this.onStoreRequested,
    super.key,
  });

  final HomeController homeController;
  final PetController petController;
  final StoreController storeController;
  final AppPreferencesController preferencesController;
  final Future<void> Function() onExitRequested;
  final Future<void> Function()? onPlayRequested;
  final Future<void> Function()? onStoreRequested;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomePetScene _scene;
  Timer? _messageTimer;
  String? _systemMessage;
  bool _pauseOpen = false;
  bool _foodInventoryOpen = false;
  bool _exitRequested = false;

  @override
  void initState() {
    super.initState();
    _scene = HomePetScene(
      storeController: widget.storeController,
      onFoodTap: _handleFoodTap,
      onCleaningContactStarted: _beginCleaningContact,
      onCleaningContactStopped: widget.homeController.suspendCleaningContact,
      onCleaningGestureEnded: widget.homeController.finishCleaningGesture,
      isFoodToolSelected: () =>
          widget.homeController.selectedTool == CareTool.food,
      isCleaningToolSelected: () =>
          widget.homeController.selectedTool == CareTool.soap,
      isCleaningActive: () => widget.homeController.isCleaning,
      isFullyClean: () => widget.homeController.petState.cleanliness >= 9.999,
      petState: () => widget.homeController.petState,
      petActivity: () => widget.homeController.activity,
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<FoodFeedResult> _handleFoodTap() {
    return widget.homeController.handleSelectedFoodTap();
  }

  bool _beginCleaningContact() {
    final result = widget.homeController.beginCleaningContact();
    _showNotice(result.notice);
    return result.accepted;
  }

  Future<void> _openFoodInventory() async {
    if (_foodInventoryOpen) {
      return;
    }
    final allowed = await widget.homeController.prepareForFoodInventory();
    if (!allowed || !mounted) {
      return;
    }
    widget.homeController.clearFoodSelectionIfUnavailable(
      widget.storeController.foodQuantity,
    );
    setState(() {
      _foodInventoryOpen = true;
    });
  }

  void _closeFoodInventory() {
    if (!_foodInventoryOpen || !mounted) {
      return;
    }
    setState(() {
      _foodInventoryOpen = false;
    });
  }

  void _selectFood(String foodId) {
    widget.homeController.toggleFoodSelection(foodId);
    _closeFoodInventory();
  }

  Future<void> _openFoodPurchase() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FoodPurchaseDialog(
        storeController: widget.storeController,
      ),
    );
  }

  Future<void> _requestPlay() async {
    final callback = widget.onPlayRequested;
    if (callback == null) {
      return;
    }
    _closeFoodInventory();
    final result = await widget.homeController.prepareForGameSelection();
    _showNotice(result.notice);
    if (!result.accepted) {
      return;
    }
    await callback();
  }

  Future<void> _requestStore([Future<void> Function()? requestedCallback]) async {
    final callback = requestedCallback ?? widget.onStoreRequested;
    if (callback == null) {
      return;
    }
    _closeFoodInventory();
    final allowed = await widget.homeController.prepareForNavigation();
    if (!allowed) {
      return;
    }

    _scene.pauseEngine();
    try {
      await callback();
    } finally {
      _scene.resumeEngine();
    }
  }

  Future<void> _toggleRest() async {
    _closeFoodInventory();
    final notice = await widget.homeController.toggleResting();
    _showNotice(notice);
  }

  Future<void> _openPause() async {
    if (_pauseOpen) {
      return;
    }
    _closeFoodInventory();
    await widget.homeController.prepareForPauseOverlay();
    if (!mounted) {
      return;
    }
    setState(() {
      _pauseOpen = true;
    });
  }

  void _closePause() {
    if (!_pauseOpen || !mounted) {
      return;
    }
    setState(() {
      _pauseOpen = false;
    });
  }

  Future<void> _confirmExit() async {
    if (_exitRequested) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salir del juego'),
          content: const Text('¿Quieres salir del juego?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _exitRequested = true;
    });
    await widget.onExitRequested();
  }

  void _showNotice(HomeNotice? notice) {
    if (notice == null || !mounted) {
      return;
    }
    _messageTimer?.cancel();
    setState(() {
      _systemMessage = _noticeText(notice);
    });
    _messageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _systemMessage = null;
      });
    });
  }

  String _noticeText(HomeNotice notice) {
    return switch (notice) {
      HomeNotice.alreadySatisfied => 'nti está satisfecho.',
      HomeNotice.alreadyClean => 'nti ya está limpio.',
      HomeNotice.restNotNeeded => 'nti aún tiene energía.',
      HomeNotice.needsRest => 'No tienes suficiente energía.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final topBarListenable = Listenable.merge(<Listenable>[
      widget.homeController,
      widget.storeController,
    ]);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Flame ocupa todo el Home: Azael conserva RoomBackground + Nti.
          GameWidget(game: _scene),
          // Nuestra composición Flutter permanece por encima.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final needHeight = (constraints.maxHeight * 0.078)
                    .clamp(48.0, 58.0)
                    .toDouble();
                final actionHeight = (constraints.maxHeight * 0.15)
                    .clamp(94.0, 124.0)
                    .toDouble();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
                  child: Column(
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: topBarListenable,
                        builder: (context, _) {
                          return HomeTopBar(
                            coins: widget.storeController.coins,
                            health: widget.homeController.health,
                            onStorePressed: () => unawaited(_requestStore()),
                            onPausePressed: () => unawaited(_openPause()),
                            storeEnabled:
                                widget.onStoreRequested != null &&
                                widget.homeController.canNavigateFromHome,
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: needHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE8C9CF,
                            ).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                              width: 1.5,
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x28000000),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: AnimatedBuilder(
                              animation: widget.homeController,
                              builder: (context, _) => _buildNeedRow(),
                            ),
                          ),
                        ),
                      ),
                      // La zona central queda libre de widgets interceptores:
                      // los taps llegan a Nti y los gestos de cuidado a Flame.
                      const Expanded(child: SizedBox.expand()),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: actionHeight,
                        child: AnimatedBuilder(
                          animation: widget.homeController,
                          builder: (context, _) => _buildActionRow(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: widget.homeController,
              builder: (context, _) {
                return IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    opacity: widget.homeController.isResting ? 1 : 0,
                    child: const ColoredBox(color: Color(0x33271833)),
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: widget.homeController,
            builder: (context, _) {
              final resting = widget.homeController.isResting;
              return SafeArea(
                child: Align(
                  alignment: const Alignment(0.32, -0.18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    reverseDuration: const Duration(milliseconds: 190),
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                        reverseCurve: Curves.easeIn,
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: resting
                        ? const PetMessageBubble(
                            key: ValueKey<String>('nti-sleep-zzz'),
                            message: 'Zzz…',
                            compact: true,
                          )
                        : const SizedBox(
                            key: ValueKey<String>('nti-sleep-awake'),
                          ),
                  ),
                ),
              );
            },
          ),
          if (_systemMessage != null)
            SafeArea(
              child: Align(
                alignment: const Alignment(0, -0.53),
                child: IgnorePointer(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: PetMessageBubble(message: _systemMessage!),
                  ),
                ),
              ),
            ),
          if (_foodInventoryOpen)
            FoodInventoryOverlay(
              storeController: widget.storeController,
              selectedFoodId: widget.homeController.selectedFoodId,
              onFoodSelected: _selectFood,
              onOpenPurchase: () => unawaited(_openFoodPurchase()),
              onClose: _closeFoodInventory,
            ),
          if (_pauseOpen)
            PauseOverlay(
              preferencesController: widget.preferencesController,
              onContinue: _closePause,
              onExitRequested: _confirmExit,
              showExit: defaultTargetPlatform == TargetPlatform.android,
            ),
          if (_exitRequested)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNeedRow() {
    final state = widget.homeController.petState;
    return Row(
      children: <Widget>[
        Expanded(
          child: NeedStatusCard(
            label: 'Comida',
            value: state.hunger,
            color: const Color(0xFF62C46E),
            iconAsset: AppUiAssets.foodIcon,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: NeedStatusCard(
            label: 'Limpieza',
            value: state.cleanliness,
            color: const Color(0xFF55BDEB),
            iconAsset: AppUiAssets.cleanlinessIcon,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: NeedStatusCard(
            label: 'Energía',
            value: state.energy,
            color: const Color(0xFFF2A65A),
            iconAsset: AppUiAssets.energyIcon,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: NeedStatusCard(
            label: 'Felicidad',
            value: state.fun,
            color: const Color(0xFFE46AB1),
            iconAsset: AppUiAssets.funIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    final controller = widget.homeController;
    return Row(
      children: <Widget>[
        Expanded(
          child: HomeActionButton(
            label: 'Comer',
            backgroundAsset: AppUiAssets.actionFeed,
            enabled: controller.canUseCareActions,
            selected: controller.selectedTool == CareTool.food,
            onPressed: () => unawaited(_openFoodInventory()),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: HomeActionButton(
            label: 'Limpiar',
            backgroundAsset: AppUiAssets.actionClean,
            enabled: controller.canUseCareActions,
            selected: controller.selectedTool == CareTool.soap,
            onPressed: () {
              _closeFoodInventory();
              unawaited(controller.toggleTool(CareTool.soap));
            },
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: HomeActionButton(
            label: 'Jugar',
            backgroundAsset: AppUiAssets.actionPlay,
            enabled:
                widget.onPlayRequested != null &&
                controller.canNavigateFromHome,
            onPressed: () => unawaited(_requestPlay()),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: HomeActionButton(
            label: 'Dormir',
            backgroundAsset: AppUiAssets.actionSleep,
            enabled: controller.canToggleResting,
            selected: controller.isResting,
            onPressed: () => unawaited(_toggleRest()),
          ),
        ),
      ],
    );
  }
}
