import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/app/settings/app_preferences_repository.dart';
import 'package:flutter_application_1/integration/audio/audio_service.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({
    required this.repository,
    required this.audioService,
  });

  final AppPreferencesRepository repository;
  final AudioService audioService;

  AppPreferences _preferences = AppPreferences.initial;
  bool _initialized = false;
  Future<void> _saveTail = Future<void>.value();

  AppPreferences get preferences => _preferences;
  double get musicVolume => _preferences.musicVolume;
  double get effectsVolume => _preferences.effectsVolume;
  bool get vibrationEnabled => _preferences.vibrationEnabled;
  NotificationPromptDecision get notificationPromptDecision =>
      _preferences.notificationPromptDecision;
  Map<String, String> get notificationLastVariants =>
      _preferences.notificationLastVariants;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    final saved = await repository.load();
    _preferences = saved ?? AppPreferences.initial;
    _initialized = true;
    await _applyToService();
    if (saved == null) {
      await persist();
    }
    notifyListeners();
  }

  void updateMusicVolume(double value) {
    final normalized = _normalizeVolume(value);
    if (normalized == _preferences.musicVolume) {
      return;
    }
    _preferences = _preferences.copyWith(musicVolume: normalized);
    notifyListeners();
    unawaited(audioService.setMusicVolume(normalized));
  }

  void updateEffectsVolume(double value) {
    final normalized = _normalizeVolume(value);
    if (normalized == _preferences.effectsVolume) {
      return;
    }
    _preferences = _preferences.copyWith(effectsVolume: normalized);
    notifyListeners();
    unawaited(audioService.setEffectsVolume(normalized));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    if (enabled == _preferences.vibrationEnabled) {
      return;
    }
    _preferences = _preferences.copyWith(vibrationEnabled: enabled);
    notifyListeners();
    await audioService.setVibrationEnabled(enabled);
    await persist();
  }


  Future<void> setNotificationPromptDecision(
    NotificationPromptDecision decision,
  ) async {
    if (decision == _preferences.notificationPromptDecision) {
      return;
    }
    _preferences = _preferences.copyWith(notificationPromptDecision: decision);
    notifyListeners();
    await persist();
  }

  Future<void> setNotificationLastVariants(
    Map<String, String> variants,
  ) async {
    if (variants.isEmpty) {
      return;
    }
    final updated = <String, String>{..._preferences.notificationLastVariants};
    var changed = false;
    for (final entry in variants.entries) {
      final variant = entry.value;
      if (variant != 'a' && variant != 'b') {
        throw ArgumentError.value(variant, 'variant', 'Debe ser a o b.');
      }
      if (updated[entry.key] != variant) {
        updated[entry.key] = variant;
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    _preferences = _preferences.copyWith(notificationLastVariants: updated);
    notifyListeners();
    await persist();
  }

  Future<void> persist() {
    _requireInitialized();
    final snapshot = _preferences;
    final completer = Completer<void>();
    _saveTail = _saveTail.then((_) async {
      try {
        await repository.save(snapshot);
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> flushPendingSaves() async {
    await _saveTail;
  }

  Future<void> _applyToService() async {
    await audioService.setMusicVolume(_preferences.musicVolume);
    await audioService.setEffectsVolume(_preferences.effectsVolume);
    await audioService.setVibrationEnabled(_preferences.vibrationEnabled);
  }

  double _normalizeVolume(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Debe ser un número finito.');
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppPreferencesController debe inicializarse antes de guardar.',
      );
    }
  }
}
