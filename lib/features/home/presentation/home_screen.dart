import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/features/home/application/care_tool.dart';
import 'package:flutter_application_1/features/home/application/home_controller.dart';
import 'package:flutter_application_1/features/home/application/home_notice.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_action_button.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/home_top_bar.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/need_status_card.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pause_overlay.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pet_visual_slot.dart';
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
  String? _petMessage;
  bool _pauseOpen = false;
  bool _exitRequested = false;

  @override
  void initState() {
    super.initState();
    _scene = HomePetScene(
      petController: widget.petController,
      storeController: widget.storeController,
      onPetTap: _handlePetTap,
      onCleaningContactStarted: _beginCleaningContact,
      onCleaningContactStopped:
          widget.homeController.suspendCleaningContact,
      onCleaningGestureEnded: widget.homeController.finishCleaningGesture,
      isCleaningToolSelected: () =>
          widget.homeController.selectedTool == CareTool.soap,
      isCleaningActive: () => widget.homeController.isCleaning,
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _handlePetTap() {
    _showNotice(widget.homeController.handlePetTap());
  }

  bool _beginCleaningContact() {
    final result = widget.homeController.beginCleaningContact();
    _showNotice(result.notice);
    return result.accepted;
  }

  Future<void> _requestPlay() async {
    final callback = widget.onPlayRequested;
    if (callback == null) {
      return;
    }
    final result = await widget.homeController.prepareForGameSelection();
    _showNotice(result.notice);
    if (!result.accepted) {
      return;
    }
    await callback();
  }

  Future<void> _requestStore() async {
    final callback = widget.onStoreRequested;
    if (callback == null) {
      return;
    }
    final allowed = await widget.homeController.prepareForNavigation();
    if (!allowed) {
      return;
    }
    await callback();
  }

  Future<void> _toggleRest() async {
    final notice = await widget.homeController.toggleResting();
    _showNotice(notice);
  }

  Future<void> _openPause() async {
    if (_pauseOpen) {
      return;
    }
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
      _petMessage = _noticeText(notice);
    });
    _messageTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _petMessage = null;
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
          Image.asset(AppUiAssets.homeBackground, fit: BoxFit.cover),
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
                            color: const Color(0xFFE8C9CF).withValues(alpha: 0.88),
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
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: AnimatedBuilder(
                              animation: widget.homeController,
                              builder: (context, _) => _buildNeedRow(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: PetVisualSlot(
                          message: _petMessage,
                          petVisual: GameWidget(game: _scene),
                        ),
                      ),
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
            onPressed: () {
              unawaited(controller.toggleTool(CareTool.food));
            },
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
