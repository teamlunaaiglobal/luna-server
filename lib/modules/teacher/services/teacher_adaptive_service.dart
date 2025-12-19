import 'dart:async';
// [수정] 불필요한 import 제거됨 (dart:math, flutter/foundation)
import '../models/study_material.dart';
import 'teacher_ai_service.dart';

class TeacherAdaptiveService {
  TeacherAdaptiveService._privateConstructor();
  static final TeacherAdaptiveService instance = TeacherAdaptiveService._privateConstructor();

  final TeacherAIService _aiService = TeacherAIService.instance;

  // 언어 설정
  String nativeLanguage = "Korean";
  String targetLanguage = "English";

  /// [핵심] 적응형 회화 시나리오 생성 (Adaptive Scenario)
  Future<StudyMaterial> generateAdaptiveContent({
    required String topic, 
    double? forceDifficulty
  }) async {
    // 1. 사용자 레벨 분석
    final history = _aiService.getLearningHistory();
    double currentLevel = 1.0;
    
    if (history.isNotEmpty) {
      double total = 0;
      history.forEach((_, v) => total += v['level'] ?? 1.0);
      currentLevel = total / history.length;
    }

    // 난이도 결정
    final difficulty = forceDifficulty ?? (currentLevel + 0.5).clamp(1.0, 10.0);

    // 2. AI 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 모국어 : 외국어 쌍 데이터 생성
    final String contentPaired = _getSimulatedPairContent(topic, difficulty);

    return StudyMaterial(
      id: 'adapt_${DateTime.now().millisecondsSinceEpoch}',
      type: 'Conversation',
      title: '$topic (Lv.${difficulty.toStringAsFixed(1)})',
      contentOriginal: contentPaired, 
      contentTranslated: "Adaptive Learning Content", 
      difficultyLevel: difficulty,
      keywords: [nativeLanguage, targetLanguage, topic],
      createdAt: DateTime.now(),
    );
  }

  /// [헬퍼] TTS용: 문장에서 외국어 부분만 추출
  String extractTargetAudio(String pairedSentence) {
    if (pairedSentence.contains(":")) {
      return pairedSentence.split(":")[1].trim();
    }
    return pairedSentence;
  }

  // 더미 데이터 생성기
  String _getSimulatedPairContent(String topic, double level) {
    if (level < 3.0) {
      return "안녕하세요 : Hello\n반갑습니다 : Nice to meet you\n이름이 뭐예요? : What is your name?";
    } else if (level < 6.0) {
      return "오늘 날씨가 참 좋네요 : The weather is really nice today\n주말에 뭐 할 계획이에요? : What are your plans for the weekend?\n저는 영화 보러 갈 생각이에요 : I'm thinking of going to see a movie";
    } else {
      return "이 프로젝트의 마감 기한을 준수하는 것이 중요합니다 : It is crucial to adhere to the deadline for this project\n시장 조사 결과가 긍정적으로 나왔습니다 : The market research results came out positive\n다음 단계로 넘어갑시다 : Let's proceed to the next step";
    }
  }
}