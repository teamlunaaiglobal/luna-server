import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../legacy/luna_brain.dart' as legacy_brain;

/// 감정 태그 정의 (레거시 호환용)
enum EmotionTag { neutral, happy, sad, angry, tired, excited }

class LunaTTSService {
  // ---------------------------------------------------------------------------
  // [보존됨] AI 루나 목소리 변환 키 (대표님 코드 유지)
  // ---------------------------------------------------------------------------
  static const String _voiceKey1 = "KEY_REMOVED_FOR_SECURITY";
  static const String _voiceKey2 = "KEY_REMOVED_FOR_SECURITY";
  // ---------------------------------------------------------------------------

  // [혁신] 싱글톤 패턴 (메모리 최적화)
  static final LunaTTSService instance = LunaTTSService._internal();
  factory LunaTTSService() => instance;
  LunaTTSService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  /// 초기화
  Future<void> init() async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  /// [통합] 텍스트 말하기 (대표님 로직 + 감정 표현 결합)
  /// emotion 인자는 선택사항입니다.
  Future<void> speak(String text, {EmotionTag emotion = EmotionTag.neutral}) async {
    if (text.isEmpty) return;
    
    // [보존됨] 디버그 모드에서 키 확인 로그 출력
    if (kDebugMode) {
      print("Luna Voice Key 1: ${_voiceKey1.substring(0, 5)}..."); 
      print("Luna Voice Key 2: ${_voiceKey2.substring(0, 5)}..."); 
    }

    // [혁신] 감정에 따른 목소리 톤 자동 조절
    _applyEmotion(emotion);

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }
  
  /// [NEW] EmotionEngine의 EmotionTag로 말하기
  Future<void> speakWithEmotion(String text, legacy_brain.EmotionTag tag) async {
    EmotionTag mappedEmotion = _mapEmotionTag(tag);
    await speak(text, emotion: mappedEmotion);
  }
  
  /// [NEW] EmotionEngine EmotionTag -> TTS EmotionTag 매핑
  EmotionTag _mapEmotionTag(legacy_brain.EmotionTag tag) {
    switch (tag) {
      case legacy_brain.EmotionTag.seeksEmotionalConnection:
      case legacy_brain.EmotionTag.needsReassurance:
        return EmotionTag.sad;
      case legacy_brain.EmotionTag.motivated:
      case legacy_brain.EmotionTag.confident:
        return EmotionTag.happy;
      case legacy_brain.EmotionTag.tired:
      case legacy_brain.EmotionTag.mentallyOverloaded:
        return EmotionTag.tired;
      case legacy_brain.EmotionTag.frustrated:
        return EmotionTag.angry;
      case legacy_brain.EmotionTag.calmFocused:
      case legacy_brain.EmotionTag.executionMode:
      default:
        return EmotionTag.neutral;
    }
  }

  /// [혁신] 감정별 톤 매핑 로직
  void _applyEmotion(EmotionTag emotion) {
    switch (emotion) {
      case EmotionTag.happy:
      case EmotionTag.excited:
        _flutterTts.setPitch(1.2); _flutterTts.setSpeechRate(0.6); break;
      case EmotionTag.sad:
      case EmotionTag.tired:
        _flutterTts.setPitch(0.8); _flutterTts.setSpeechRate(0.4); break;
      case EmotionTag.angry:
        _flutterTts.setPitch(0.7); _flutterTts.setSpeechRate(0.6); break;
      default:
        _flutterTts.setPitch(1.0); _flutterTts.setSpeechRate(0.5);
    }
  }

  /// [보존됨] 바이너리 오디오 데이터 재생 함수
  Future<void> playAudio(Uint8List audioBytes) async {
    try {
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      debugPrint("AudioPlayer Error: $e");
    }
  }

  /// [보존됨] 소리 멈춤 (둘 다 정지)
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("Stop Error: $e");
    }
  }
}
