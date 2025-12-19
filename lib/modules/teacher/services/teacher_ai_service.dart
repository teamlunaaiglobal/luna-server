import 'dart:async';
// [수정] 불필요한 dart:math, flutter/foundation 제거 완료
import 'package:flutter_tts/flutter_tts.dart';
import '../models/study_material.dart';

class TeacherAIService {
  TeacherAIService._privateConstructor();
  static final TeacherAIService instance = TeacherAIService._privateConstructor();

  final FlutterTts _tts = FlutterTts();
  Map<String, double> userProgress = {};
  Map<String, double> userLevel = {};

  Future<void> initialize() async {
    await _tts.setLanguage("en-US");
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  // 눈(Vision) 기능 들어갈 자리 (에러 방지용 껍데기)
  Future<String> analyzeImageAndGetTopic(String imagePath) async {
    return "Free Talking"; 
  }

  Future<StudyMaterial> fetchMaterial({required String type, double? targetDifficulty}) async {
    final id = 'mat_${DateTime.now().millisecondsSinceEpoch}';
    return StudyMaterial(
      id: id,
      type: type,
      title: 'AI Recommends: $type',
      contentOriginal: 'This is sample content for $type.',
      contentTranslated: '테스트용 샘플 문장입니다.',
      difficultyLevel: 3.0,
      keywords: ['Test'],
      createdAt: DateTime.now(),
    );
  }

  void updateProgress(String materialId, double progress) {
    userProgress[materialId] = progress;
  }

  Map<String, Map<String, double>> getLearningHistory() {
    final history = <String, Map<String, double>>{};
    for (var id in userProgress.keys) {
      history[id] = {
        'progress': userProgress[id] ?? 0.0,
        'level': userLevel[id] ?? 0.0,
      };
    }
    return history;
  }
}