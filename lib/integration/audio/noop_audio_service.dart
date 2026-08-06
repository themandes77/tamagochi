import 'package:flutter_application_1/integration/audio/audio_service.dart';

class NoOpAudioService implements AudioService {
  const NoOpAudioService();

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
