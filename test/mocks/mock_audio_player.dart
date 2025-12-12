import 'package:just_audio/just_audio.dart';
import 'dart:async';

/// Mock AudioPlayer dla testów - uproszczona wersja
/// Uwaga: just_audio nie ma oficjalnego mocka, więc tworzymy prosty wrapper
class MockAudioPlayer {
  final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();
  final StreamController<PlaybackEvent> _playbackEventController = StreamController<PlaybackEvent>.broadcast();

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<PlaybackEvent> get playbackEventStream => _playbackEventController.stream;

  Future<Duration?> setUrl(String url, {Map<String, String>? headers, Duration? initialPosition, bool preload = true, dynamic tag}) async {
    _emitState();
    await Future.delayed(const Duration(milliseconds: 10));
    _emitState();
    return Duration.zero;
  }

  Future<void> play() async {
    _emitState();
  }

  Future<void> stop() async {
    _emitState();
  }

  Future<void> dispose() async {
    await _playerStateController.close();
    await _playbackEventController.close();
  }

  void _emitState() {
    // PlayerState constructor wymaga dwóch parametrów pozycyjnych
    // W testach możemy pominąć szczegóły implementacji
    // Uwaga: Ten mock nie jest obecnie używany w testach widgetów
    // ponieważ MapScreen tworzy własny AudioPlayer
  }
}
