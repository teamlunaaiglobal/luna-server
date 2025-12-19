import 'dart:math';
import 'teacher_ai_service.dart';
import '../models/study_material.dart';

class TeacherRecommendService {
  TeacherRecommendService._privateConstructor();
  static final TeacherRecommendService instance = TeacherRecommendService._privateConstructor();

  final TeacherAIService _aiService = TeacherAIService.instance;

  /// [알고리즘] 사용자 이력 기반 추천 자료 생성
  Future<List<StudyMaterial>> fetchRecommendedMaterials({int count = 3}) async {
    final history = _aiService.getLearningHistory();
    final recommended = <StudyMaterial>[];

    // 사용자의 평균 레벨 계산 (이력이 없으면 기본 3.0)
    double avgLevel = 3.0;
    if (history.isNotEmpty) {
      double totalLevel = 0;
      int count = 0;
      history.forEach((_, data) {
        totalLevel += data['level'] ?? 0;
        count++;
      });
      if (count > 0) avgLevel = totalLevel / count;
    }

    // 추천 로직: 평균 레벨 근처의 난이도로 다양한 장르 생성
    final types = ['Scenario', 'News', 'RolePlay', 'Daily'];
    
    for (int i = 0; i < count; i++) {
      final type = types[Random().nextInt(types.length)];
      // 난이도 변주 (평균 레벨 ±1.0 범위)
      final targetLevel = (avgLevel - 1.0 + Random().nextDouble() * 2.0).clamp(1.0, 10.0);
      
      final mat = await _aiService.fetchMaterial(type: type, targetDifficulty: targetLevel);
      recommended.add(mat);
    }
    
    return recommended;
  }
}