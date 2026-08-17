import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/app/app_bootstrap.dart';
import 'package:flutter_application_1/app/boot/app_boot_status.dart';
import 'package:flutter_application_1/app/presentation/app_loading_screen.dart';
import 'package:flutter_application_1/core/persistence/storage_notice.dart';
import 'package:flutter_application_1/core/time/pet_session_ticker.dart';
import 'package:flutter_application_1/features/home/presentation/home_screen.dart';
import 'package:flutter_application_1/integration/minigames/minigame_host_screen.dart';
import 'package:flutter_application_1/integration/minigames/minigame_fun_reward_policy.dart';
import 'package:flutter_application_1/integration/minigames/minigame_session_result.dart';
import 'package:flutter_application_1/integration/store/store_asset_precache.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/integration/store/store_host_screen.dart';

class NtiApp extends StatefulWidget {
  const NtiApp({required this.bootstrap, super.key});

  final AppBootstrap bootstrap;

  @override
  State<NtiApp> createState() => _NtiAppState();
}

class _NtiAppState extends State<NtiApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late AppBootstrap _bootstrap;
  late final PetSessionTicker _sessionTicker;
  Future<void> _lifecycleTail = Future<void>.value();

  AppBootStatus _bootStatus = AppBootStatus.loading;
  double _bootProgress = 0.03;
  bool _retryInProgress = false;
  bool _sessionPaused = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap = widget.bootstrap;
    WidgetsBinding.instance.addObserver(this);
    _sessionTicker = PetSessionTicker(
      vsync: this,
      onElapsed: _onSessionTick,
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final minimumDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1100),
    );
    try {
      await Future.wait(<Future<void>>[
        _bootstrap.initialize(onProgress: _setBootProgress),
        minimumDisplay,
      ]);
      if (!mounted || _disposed) {
        return;
      }
      setState(() {
        _bootProgress = 1.0;
        _bootStatus = AppBootStatus.ready;
        _retryInProgress = false;
      });
      _startTicker();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStorageNotices(_bootstrap.noticeCenter.drain());
        if (mounted) {
          unawaited(StoreAssetPrecache.precache(context));
        }
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.bootstrap',
        ),
      );
      if (!mounted || _disposed) {
        return;
      }
      setState(() {
        _bootStatus = AppBootStatus.error;
        _retryInProgress = false;
      });
    }
  }

  void _setBootProgress(double progress) {
    if (!mounted || _disposed || _bootStatus != AppBootStatus.loading) {
      return;
    }
    final normalized = progress.clamp(_bootProgress, 1.0).toDouble();
    setState(() {
      _bootProgress = normalized;
    });
  }

  Future<void> _retryInitialization() async {
    if (_retryInProgress || _disposed) {
      return;
    }
    setState(() {
      _retryInProgress = true;
      _bootStatus = AppBootStatus.loading;
      _bootProgress = 0.03;
    });
    _stopTicker();
    _sessionPaused = false;

    final previousBootstrap = _bootstrap;
    try {
      await previousBootstrap.dispose();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.bootstrap.retry_dispose',
        ),
      );
    }

    _bootstrap = AppBootstrap.create();
    await _initialize();
  }

  void _onSessionTick(Duration elapsed) {
    if (_bootStatus != AppBootStatus.ready ||
        _sessionPaused ||
        _disposed) {
      return;
    }
    _bootstrap.petLifecycleCoordinator.advance(elapsed);
  }

  void _startTicker() {
    if (_sessionTicker.isActive ||
        _bootStatus != AppBootStatus.ready ||
        _sessionPaused ||
        _disposed) {
      return;
    }
    _sessionTicker.start();
  }

  void _stopTicker() {
    _sessionTicker.stop();
  }

  Future<void> _openMinigames() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MinigameHostScreen(
          ntiOutfit: _bootstrap.storeController.selectedOutfit,
          onGameStartRequested: (costPolicy) async {
            final result = await _bootstrap.homeController.tryStartPlaying(
              costPolicy: costPolicy,
            );
            return result.accepted;
          },
          onGameOverDetected: _completeMinigameSession,
          onGameSessionEnded: () async {
            await _bootstrap.storeController.persistRuntimeCoins();
            await _bootstrap.homeController.cancelPlaying();
          },
        ),
      ),
    );
  }

  Future<void> _completeMinigameSession(
    MinigameSessionResult result,
  ) async {
    final funGained = MinigameFunRewardPolicy.rewardFor(
      result,
      maximumReward:
          _bootstrap.petController.rules.maximumFunRewardPerGame,
    );

    // Game Over es el cierre real de la partida para Pet. Persistimos la
    // diversión antes de sincronizar monedas; si Store necesitara reintento,
    // la salida de la sesión conserva su checkpoint existente.
    await _bootstrap.homeController.finishPlaying(funGained: funGained);
    await _bootstrap.storeController.persistRuntimeCoins();
  }

  Future<void> _openStore({ShopItemKind initialKind = ShopItemKind.outfit}) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StoreHostScreen(
          controller: _bootstrap.storeController,
          initialKind: initialKind,
        ),
      ),
    );
  }

  Future<void> _exitApplication() async {
    try {
      await _bootstrap.exitCoordinator
          .saveBeforeExit()
          .timeout(const Duration(seconds: 2));
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.exit_save',
        ),
      );
    } finally {
      await SystemNavigator.pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _queueLifecycleOperation(_resumeSession);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _queueLifecycleOperation(_pauseSession);
        break;
    }
  }

  void _queueLifecycleOperation(Future<void> Function() operation) {
    _lifecycleTail = _lifecycleTail.then((_) => operation()).catchError(
      (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'nt_tamagochi.lifecycle',
          ),
        );
      },
    );
  }

  Future<void> _pauseSession() async {
    if (_bootStatus != AppBootStatus.ready ||
        _sessionPaused ||
        _disposed) {
      return;
    }
    _sessionPaused = true;
    _stopTicker();
    _bootstrap.homeController.resetTransientUiForPause();
    await _bootstrap.feedingCoordinator.flushPendingMaterializations();
    await _bootstrap.petLifecycleCoordinator.pause();
    await _bootstrap.storeController.persistRuntimeCoins();
  }

  Future<void> _resumeSession() async {
    if (_bootStatus != AppBootStatus.ready ||
        !_sessionPaused ||
        _disposed) {
      return;
    }
    await _bootstrap.petLifecycleCoordinator.resume();
    _sessionPaused = false;
    _startTicker();
    _showStorageNotices(_bootstrap.noticeCenter.drain());
  }

  void _showStorageNotices(List<StorageNotice> notices) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) {
      return;
    }
    for (final notice in notices) {
      messenger.showSnackBar(
        SnackBar(content: Text(notice.message)),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    _sessionTicker.dispose();
    unawaited(_bootstrap.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7E57C2),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_bootStatus != AppBootStatus.ready) {
      return AppLoadingScreen(
        status: _bootStatus,
        progress: _bootProgress,
        onRetry: _retryInitialization,
        retryInProgress: _retryInProgress,
      );
    }
    return HomeScreen(
      homeController: _bootstrap.homeController,
      petController: _bootstrap.petController,
      storeController: _bootstrap.storeController,
      preferencesController: _bootstrap.preferencesController,
      onPlayRequested: _openMinigames,
      onStoreRequested: () => _openStore(),
      onExitRequested: _exitApplication,
    );
  }
}
