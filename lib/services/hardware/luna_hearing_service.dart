import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class LunaHearingService {
  static final LunaHearingService instance = LunaHearingService._internal();
  factory LunaHearingService() => instance;
  LunaHearingService._internal();

  final SpeechToText _speech = SpeechToText();
  // 실시간 텍스트 스트림 (UI 자막용)
  final _textStream = StreamController<String>.broadcast();
  Stream<String> get onText => _textStream.stream;

  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (e) => debugPrint("Hearing Error: $e"),
      );
    }
  }

  void startListening() {
    if (!_isInitialized) init();
    
    _speech.listen(
      onResult: (result) => _textStream.add(result.recognizedWords),
      localeId: 'ko_KR',
      // [수정] Deprecated 된 파라미터를 SpeechListenOptions로 이동
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void stopListening() => _speech.stop();
}