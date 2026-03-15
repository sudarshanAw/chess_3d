/// Audio service for playing game sounds.
/// Currently a stub — infrastructure is in place for adding move sounds,
/// capture sounds, check alerts, and game-over music in a future update.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _enabled = true;
  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    // Future: initialize audio engine, preload sounds
  }

  void toggleSound() {
    _enabled = !_enabled;
  }

  void playMove() {
    if (!_enabled) return;
    // Future: play piece-move sound
  }

  void playCapture() {
    if (!_enabled) return;
    // Future: play capture sound
  }

  void playCheck() {
    if (!_enabled) return;
    // Future: play check alert sound
  }

  void playGameOver() {
    if (!_enabled) return;
    // Future: play game-over sound
  }

  void dispose() {
    // Future: dispose audio resources
  }
}
