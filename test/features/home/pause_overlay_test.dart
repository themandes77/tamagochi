import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/app/settings/app_preferences_repository.dart';
import 'package:flutter_application_1/features/home/presentation/widgets/pause_overlay.dart';
import 'package:flutter_application_1/integration/audio/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pause keeps the approved actions and omits main menu', (
    tester,
  ) async {
    final controller = await _controller();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              PauseOverlay(
                preferencesController: controller,
                onContinue: () {},
                onExitRequested: () async {},
                showExit: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PAUSA'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(find.text('SALIR DEL JUEGO'), findsOneWidget);
    expect(find.text('MENÚ PRINCIPAL'), findsNothing);
    expect(find.text('MÚSICA'), findsOneWidget);
    expect(find.text('EFECTOS'), findsOneWidget);
    expect(find.text('VIBRACIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-style scope hides exit and reflows without an empty slot', (
    tester,
  ) async {
    final controller = await _controller();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              PauseOverlay(
                preferencesController: controller,
                onContinue: () {},
                onExitRequested: () async {},
                showExit: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CONTINUAR'), findsOneWidget);
    expect(find.text('SALIR DEL JUEGO'), findsNothing);
    expect(find.byKey(const ValueKey('pause_version_label')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short screens preserve composition and enable scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await _controller();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              PauseOverlay(
                preferencesController: controller,
                onContinue: () {},
                onExitRequested: () async {},
                showExit: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pause_overlay_scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('pause_music_slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('pause_continue_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<AppPreferencesController> _controller() async {
  final controller = AppPreferencesController(
    repository: _MemoryPreferencesRepository(),
    audioService: _FakeAudioService(),
  );
  await controller.initialize();
  return controller;
}

class _MemoryPreferencesRepository implements AppPreferencesRepository {
  AppPreferences value = AppPreferences.initial;

  @override
  Future<AppPreferences?> load() async => value;

  @override
  Future<void> save(AppPreferences preferences) async {
    value = preferences;
  }
}

class _FakeAudioService implements AudioService {
  @override
  Future<void> playEffect(String effectId) async {}

  @override
  Future<void> setEffectsVolume(double volume) async {}

  @override
  Future<void> setMusicVolume(double volume) async {}

  @override
  Future<void> setVibrationEnabled(bool enabled) async {}

  @override
  Future<void> startMusic(String musicId) async {}

  @override
  Future<void> stopMusic() async {}
}
