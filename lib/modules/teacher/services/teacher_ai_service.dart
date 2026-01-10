import '../../../services/user/user_settings_service.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/study_material.dart';
import '../../../services/ai/ai_manager.dart';

class TeacherAIService {
  TeacherAIService._privateConstructor();
  static final TeacherAIService instance = TeacherAIService._privateConstructor();

  final FlutterTts _tts = FlutterTts();
  final AIManager _aiManager = AIManager();
  Map<String, double> userProgress = {};
  Map<String, double> userLevel = {};

  String get nativeLanguage => UserSettingsService.instance.getLanguageName(UserSettingsService.instance.homeLanguage);
  String get targetLanguage => UserSettingsService.instance.getLanguageName(UserSettingsService.instance.targetLanguage);

  Future<void> initialize() async {
    await _tts.setLanguage("en-US");
    await _aiManager.init();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  // AI로 학습 대화 생성
  Future<String> generateLearningResponse(String userInput, String topic) async {
    String prompt = '''
You are Luna, a friendly language tutor.
Student's native language: $nativeLanguage
Learning: $targetLanguage
Topic: $topic
Student said: "$userInput"
Respond naturally in $targetLanguage, then provide $nativeLanguage translation in parentheses.
Keep it conversational and encouraging.
''';
    return await _aiManager.generateResponse(userInput, prompt);
  }

  // 문장 교정
  Future<String> correctSentence(String sentence) async {
    String prompt = '''
You are an English tutor. Correct this sentence if needed:
"$sentence"
If correct, say "Perfect!". If not, provide correction with explanation in Korean.
''';
    return await _aiManager.generateResponse(sentence, prompt);
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
