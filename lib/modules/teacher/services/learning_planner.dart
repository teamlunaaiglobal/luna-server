import 'dart:math';
import '../models/study_material.dart';
import 'teacher_ai_service.dart';
import 'teacher_adaptive_service.dart';

class LearningPlanner {
  LearningPlanner._privateConstructor();
  static final LearningPlanner instance = LearningPlanner._privateConstructor();

  final TeacherAIService _aiService = TeacherAIService.instance;
  final TeacherAdaptiveService _adaptiveService = TeacherAdaptiveService.instance;

  // 1. 데일리 루틴 (기존 유지)
  Future<List<StudyMaterial>> generateDailyPlan({int count = 3}) async {
    return await _generatePlanByTopic(['Greeting', 'Daily Life', 'Expression'], count);
  }

  // 2. [Gen-4] 맥락 기반 시나리오 생성
  Future<List<StudyMaterial>> generateContextualPlan(String situation) async {
    // 예: "Coffee Shop" -> 주문, 결제, 수령 시나리오 생성
    return await _generatePlanByTopic([situation], 1); 
  }

  // 3. [Gen-4] 예측 학습 (오답 노트 리마인드)
  Future<StudyMaterial?> predictWeakPoints() async {
    final history = _aiService.getLearningHistory();
    // 점수가 낮거나(예: 0.6 미만) 오래된 항목 찾기 시뮬레이션
    // 실제로는 DB에서 조회하겠지만, 여기서는 새로운 'Review' 아이템 생성으로 대체
    if (history.isNotEmpty && Random().nextBool()) {
      return await _adaptiveService.generateAdaptiveContent(
        topic: "Review: Past Mistakes", 
        forceDifficulty: 2.0
      );
    }
    return null;
  }

  // 내부 헬퍼
  Future<List<StudyMaterial>> _generatePlanByTopic(List<String> topics, int count) async {
    final history = _aiService.getLearningHistory();
    double avgLevel = 1.0;
    if (history.isNotEmpty) {
      double total = 0;
      history.forEach((_, v) => total += v['level'] ?? 1.0);
      avgLevel = total / history.length;
    }

    List<StudyMaterial> plan = [];
    for (int i = 0; i < count; i++) {
      final topic = topics[i % topics.length];
      final difficulty = (avgLevel + (i * 0.5)).clamp(1.0, 10.0);
      final content = await _adaptiveService.generateAdaptiveContent(
        topic: topic, 
        forceDifficulty: difficulty
      );
      plan.add(content);
    }
    return plan;
  }
}