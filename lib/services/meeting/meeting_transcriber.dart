import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/meeting/transcript.dart';

class MeetingTranscriber {
  static final MeetingTranscriber instance = MeetingTranscriber._internal();
  factory MeetingTranscriber() => instance;
  MeetingTranscriber._internal();

  final SpeechToText _stt = SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  final List<TranscriptSegment> _segments = [];
  final StringBuffer _fullText = StringBuffer();
  
  int _speakerCount = 1;
  String _currentSpeaker = 'Speaker 1';
  DateTime? _segmentStartTime;

  bool get isListening => _isListening;
  String get currentText => _fullText.toString();

  /// 초기화
  Future<bool> init() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _stt.initialize(
      onStatus: (status) => debugPrint('🎤 STT Status: $status'),
      onError: (error) => debugPrint('❌ STT Error: $error'),
    );
    
    if (_isInitialized) {
      debugPrint('✅ STT 초기화 완료');
    } else {
      debugPrint('❌ STT 초기화 실패');
    }
    
    return _isInitialized;
  }

  /// 실시간 전사 시작
  Future<void> startTranscribing({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      await init();
    }
    
    if (!_isInitialized || _isListening) return;

    _segments.clear();
    _fullText.clear();
    _segmentStartTime = DateTime.now();

    _isListening = true;

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            // 세그먼트 추가
            final segment = TranscriptSegment(
              speaker: _currentSpeaker,
              text: text,
              startTime: DateTime.now().difference(_segmentStartTime!),
              endTime: DateTime.now().difference(_segmentStartTime!),
              confidence: result.confidence,
            );
            _segments.add(segment);
            
            _fullText.writeln('[$_currentSpeaker] $text');
            onResult(text);
          }
        } else {
          // 부분 결과
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko_KR',
      listenOptions: SpeechListenOptions(partialResults: true),
    );

    debugPrint('🎤 실시간 전사 시작');
  }

  /// 전사 중지
  Future<Transcript?> stopTranscribing(String meetingId) async {
    if (!_isListening) return null;

    await _stt.stop();
    _isListening = false;

    final transcript = Transcript(
      meetingId: meetingId,
      segments: List.from(_segments),
      fullText: _fullText.toString(),
      createdAt: DateTime.now(),
    );

    debugPrint('⏹️ 전사 종료: ${_segments.length}개 세그먼트');
    
    return transcript;
  }

  /// 화자 변경 (수동)
  void changeSpeaker() {
    _speakerCount++;
    _currentSpeaker = 'Speaker $_speakerCount';
    debugPrint('👤 화자 변경: $_currentSpeaker');
  }

  /// 특정 화자 지정
  void setSpeaker(String name) {
    _currentSpeaker = name;
    debugPrint('👤 화자 지정: $_currentSpeaker');
  }

  /// 지원 언어 목록
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) await init();
    final locales = await _stt.locales();
    return locales.map((l) => l.localeId).toList();
  }

  /// 리소스 해제
  void dispose() {
    _stt.stop();
    _stt.cancel();
  }
}
