import 'package:just_audio/just_audio.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();

  Future<void> load(String url) async {
    await player.setUrl(url);
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  bool get playing => player.playing;

  Future<void> dispose() async {
    await player.dispose();
  }
}
