import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static Future<void> playBGM() async {
    try {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      // await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      print("[AudioService] BGM başlatıldı (Ses dosyası eklenince çalışacak)");
    } catch (e) {
      print("BGM hatası: $e");
    }
  }

  static Future<void> stopBGM() async {
    await _bgmPlayer.stop();
  }

  static Future<void> playClick() async {
    try {
      // await _sfxPlayer.play(AssetSource('audio/click.mp3'));
      print("[AudioService] Tıklama sesi çalındı");
    } catch (e) {}
  }

  static Future<void> playStoneMove() async {
    try {
      // await _sfxPlayer.play(AssetSource('audio/stone_move.mp3'));
      print("[AudioService] Taş hareketi sesi çalındı");
    } catch (e) {}
  }

  static Future<void> playWin() async {
    try {
      // await _sfxPlayer.play(AssetSource('audio/win.mp3'));
      print("[AudioService] Kazanma sesi çalındı");
    } catch (e) {}
  }

  static Future<void> playLose() async {
    try {
      // await _sfxPlayer.play(AssetSource('audio/lose.mp3'));
      print("[AudioService] Kaybetme sesi çalındı");
    } catch (e) {}
  }
}
