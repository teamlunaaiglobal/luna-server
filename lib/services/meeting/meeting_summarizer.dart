import 'package:flutter/foundation.dart';
import '../emotion_engine.dart';

class MeetingSummarizer {
  static final MeetingSummarizer instance = MeetingSummarizer._internal();
  factory MeetingSummarizer() => instance;
  MeetingSummarizer._internal();

  final LunaBrain _brain = LunaBrain();

  /// 회의록 요약 생성
  Future<String> summarize(String transcript, {String? meetingTitle}) async {
    if (transcript.isEmpty) {
      return "전사된 내용이 없습니다.";
    }

    final prompt = '''
회의 제목: ${meetingTitle ?? '회의'}

아래 회의 내용을 요약해줘:

$transcript

---

다음 형식으로 요약해줘:

📋 **회의 요약**
(3-5문장으로 핵심 내용 요약)

🎯 **주요 결정사항**
(결정된 사항들 목록)

📌 **논의된 주제**
(논의된 주요 주제들)

⏭️ **다음 단계**
(후속 조치나 다음 회의에서 다룰 내용)
''';

    try {
      final summary = await _brain.getResponse(prompt);
      debugPrint('📝 회의 요약 완료');
      return summary;
    } catch (e) {
      debugPrint('❌ 요약 실패: $e');
      return "요약을 생성하지 못했습니다.";
    }
  }

  /// 짧은 요약 (한 줄)
  Future<String> summarizeShort(String transcript) async {
    if (transcript.isEmpty) return "";

    final prompt = '''
아래 회의 내용을 한 문장으로 요약해줘:

$transcript
''';

    try {
      return await _brain.getResponse(prompt);
    } catch (e) {
      debugPrint('❌ 짧은 요약 실패: $e');
      return "";
    }
  }

  /// 키워드 추출
  Future<List<String>> extractKeywords(String transcript) async {
    if (transcript.isEmpty) return [];

    final prompt = '''
아래 회의 내용에서 핵심 키워드 5개만 추출해줘. 쉼표로 구분해서 답해:

$transcript
''';

    try {
      final result = await _brain.getResponse(prompt);
      return result.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    } catch (e) {
      debugPrint('❌ 키워드 추출 실패: $e');
      return [];
    }
  }
}