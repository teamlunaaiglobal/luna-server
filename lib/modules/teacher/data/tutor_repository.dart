import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_level.dart';
import '../models/learning_content.dart';
import '../models/learning_progress.dart';
import '../models/roleplay_scenario.dart';

/// 튜터 데이터 저장/조회
/// 로컬 저장소 사용 (SharedPreferences)
class TutorRepository {
  static const String _progressKey = 'tutor_progress';
  static const String _contentKey = 'tutor_contents';
  static const String _scenarioKey = 'tutor_scenarios';
  static const String _vocabularyKey = 'tutor_vocabulary';

  SharedPreferences? _prefs;

  /// 싱글톤
  static final TutorRepository _instance = TutorRepository._internal();
  factory TutorRepository() => _instance;
  TutorRepository._internal();

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 학습 진도 ====================

  /// 진도 저장
  Future<bool> saveProgress(LearningProgress progress) async {
    await _ensureInitialized();
    final jsonStr = jsonEncode(progress.toJson());
    return await _prefs!.setString(
      '${_progressKey}_${progress.userId}_${progress.targetLanguage}',
      jsonStr,
    );
  }

  /// 진도 조회
  Future<LearningProgress?> getProgress(String userId, String targetLanguage) async {
    await _ensureInitialized();
    final jsonStr = _prefs!.getString('${_progressKey}_${userId}_$targetLanguage');
    if (jsonStr == null) return null;
    return LearningProgress.fromJson(jsonDecode(jsonStr));
  }

  /// 진도 생성 (없으면 새로 만듦)
  Future<LearningProgress> getOrCreateProgress(String userId, String targetLanguage) async {
    final existing = await getProgress(userId, targetLanguage);
    if (existing != null) return existing;

    final now = DateTime.now();
    final newProgress = LearningProgress(
      id: '${userId}_${targetLanguage}_${now.millisecondsSinceEpoch}',
      userId: userId,
      targetLanguage: targetLanguage,
      createdAt: now,
      updatedAt: now,
    );
    await saveProgress(newProgress);
    return newProgress;
  }

  /// 모든 진도 조회 (유저별)
  Future<List<LearningProgress>> getAllProgress(String userId) async {
    await _ensureInitialized();
    final List<LearningProgress> results = [];
    final keys = _prefs!.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('${_progressKey}_$userId')) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          results.add(LearningProgress.fromJson(jsonDecode(jsonStr)));
        }
      }
    }
    return results;
  }

  // ==================== 학습 콘텐츠 ====================

  /// 콘텐츠 저장
  Future<bool> saveContent(LearningContent content) async {
    await _ensureInitialized();
    final jsonStr = jsonEncode(content.toJson());
    return await _prefs!.setString('${_contentKey}_${content.id}', jsonStr);
  }

  /// 콘텐츠 조회
  Future<LearningContent?> getContent(String contentId) async {
    await _ensureInitialized();
    final jsonStr = _prefs!.getString('${_contentKey}_$contentId');
    if (jsonStr == null) return null;
    return LearningContent.fromJson(jsonDecode(jsonStr));
  }

  /// 레벨별 콘텐츠 조회
  Future<List<LearningContent>> getContentsByLevel(
    LearningLevel level,
    String targetLanguage,
  ) async {
    await _ensureInitialized();
    final List<LearningContent> results = [];
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_contentKey)) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          final content = LearningContent.fromJson(jsonDecode(jsonStr));
          if (content.targetLanguage == targetLanguage &&
              content.isSuitableFor(level)) {
            results.add(content);
          }
        }
      }
    }
    return results;
  }

  /// 콘텐츠 타입별 조회
  Future<List<LearningContent>> getContentsByType(
    ContentType type,
    String targetLanguage,
  ) async {
    await _ensureInitialized();
    final List<LearningContent> results = [];
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_contentKey)) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          final content = LearningContent.fromJson(jsonDecode(jsonStr));
          if (content.type == type && content.targetLanguage == targetLanguage) {
            results.add(content);
          }
        }
      }
    }
    return results;
  }

  /// 콘텐츠 삭제
  Future<bool> deleteContent(String contentId) async {
    await _ensureInitialized();
    return await _prefs!.remove('${_contentKey}_$contentId');
  }

  // ==================== 롤플레이 시나리오 ====================

  /// 시나리오 저장
  Future<bool> saveScenario(RoleplayScenario scenario) async {
    await _ensureInitialized();
    final jsonStr = jsonEncode(scenario.toJson());
    return await _prefs!.setString('${_scenarioKey}_${scenario.id}', jsonStr);
  }

  /// 시나리오 조회
  Future<RoleplayScenario?> getScenario(String scenarioId) async {
    await _ensureInitialized();
    final jsonStr = _prefs!.getString('${_scenarioKey}_$scenarioId');
    if (jsonStr == null) return null;
    return RoleplayScenario.fromJson(jsonDecode(jsonStr));
  }

  /// 레벨별 시나리오 조회
  Future<List<RoleplayScenario>> getScenariosByLevel(
    LearningLevel level,
    String targetLanguage,
  ) async {
    await _ensureInitialized();
    final List<RoleplayScenario> results = [];
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_scenarioKey)) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          final scenario = RoleplayScenario.fromJson(jsonDecode(jsonStr));
          if (scenario.recommendedLevel == level &&
              scenario.targetLanguage == targetLanguage) {
            results.add(scenario);
          }
        }
      }
    }
    return results;
  }

  /// 진행중인 시나리오 조회
  Future<List<RoleplayScenario>> getInProgressScenarios() async {
    await _ensureInitialized();
    final List<RoleplayScenario> results = [];
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith(_scenarioKey)) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          final scenario = RoleplayScenario.fromJson(jsonDecode(jsonStr));
          if (!scenario.isCompleted && scenario.currentSceneIndex > 0) {
            results.add(scenario);
          }
        }
      }
    }
    return results;
  }

  /// 시나리오 삭제
  Future<bool> deleteScenario(String scenarioId) async {
    await _ensureInitialized();
    return await _prefs!.remove('${_scenarioKey}_$scenarioId');
  }

  // ==================== 어휘 (단어장) ====================

  /// 단어 저장
  Future<bool> saveVocabulary(String userId, String word, Map<String, dynamic> data) async {
    await _ensureInitialized();
    final key = '${_vocabularyKey}_${userId}_$word';
    return await _prefs!.setString(key, jsonEncode(data));
  }

  /// 단어 조회
  Future<Map<String, dynamic>?> getVocabulary(String userId, String word) async {
    await _ensureInitialized();
    final key = '${_vocabularyKey}_${userId}_$word';
    final jsonStr = _prefs!.getString(key);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr);
  }

  /// 모든 단어 조회
  Future<List<Map<String, dynamic>>> getAllVocabulary(String userId) async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> results = [];
    final keys = _prefs!.getKeys();

    for (final key in keys) {
      if (key.startsWith('${_vocabularyKey}_$userId')) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          results.add(jsonDecode(jsonStr));
        }
      }
    }
    return results;
  }

  /// 마스터한 단어 수
  Future<int> getMasteredVocabularyCount(String userId) async {
    final allVocab = await getAllVocabulary(userId);
    return allVocab.where((v) => v['mastered'] == true).length;
  }

  // ==================== 유틸 ====================

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  /// 모든 튜터 데이터 삭제 (초기화)
  Future<void> clearAll() async {
    await _ensureInitialized();
    final keys = _prefs!.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(_progressKey) ||
          key.startsWith(_contentKey) ||
          key.startsWith(_scenarioKey) ||
          key.startsWith(_vocabularyKey)) {
        await _prefs!.remove(key);
      }
    }
  }
}
