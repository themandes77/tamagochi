abstract interface class AudioService {
  Future<void> setMusicVolume(double volume);

  Future<void> setEffectsVolume(double volume);

  Future<void> setVibrationEnabled(bool enabled);

  Future<void> playEffect(String effectId);

  Future<void> startMusic(String musicId);

  Future<void> stopMusic();
}
