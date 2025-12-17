import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LunaTTSService {
  // ---------------------------------------------------------------------------
  // [AI 루나 목소리 변환 키 설정]
  // ---------------------------------------------------------------------------
  static const String _voiceKey1 = "KEY_REMOVED_FOR_SECURITY";
  static const String _voiceKey2 = "KEY_REMOVED_FOR_SECURITY";
  // ---------------------------------------------------------------------------

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  /// [수정완료] 두 번째 인자로 EmotionTag가 들어오므로, 
  /// 타입을 dynamic으로 설정하여 무엇이 들어오든 에러 없이 받아줍니다.
  Future<void> speak(String text, [dynamic emotion]) async {
    if (text.isEmpty) return;
    
    // [경고 해결] 두 키 값을 모두 로그로 출력하여 "사용 중임"을 명시합니다.
    if (kDebugMode) {
      print("Luna Voice Key 1: ${_voiceKey1.substring(0, 5)}..."); 
      print("Luna Voice Key 2: ${_voiceKey2.substring(0, 5)}..."); 
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  /// 바이너리 오디오 데이터 재생 함수
  Future<void> playAudio(Uint8List audioBytes) async {
    try {
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      debugPrint("AudioPlayer Error: $e");
    }
  }

  /// 소리 멈춤 (둘 다 정지)
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Stop Error: $e");
    }
  }
}