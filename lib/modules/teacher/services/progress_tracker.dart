import '../models/learning_level.dart';
import '../models/learning_progress.dart';
import '../data/tutor_repository.dart';

/// 학습 진도 추적기
/// 몰래 추적 - 유저는 학습인 줄 모름!
class ProgressTracker {
  final TutorRepository _repository = TutorRepository();
  
  /// 싱글톤
  static final ProgressTracker _instance = ProgressTracker._internal();
  factory ProgressTracker() => _instance;
  ProgressTracker._internal();

  /// 현재 진도 캐시
  LearningProgress? _currentProgress;

  /// 현재 진도 가져오기
  LearningProgress? get currentProgress => _currentProgress;

  /// 초기화 (유저 + 언어)
  Future<LearningProgress> initialize(String userId, String targetLanguage) async {
    _currentProgress = await _repository.getOrCreateProgress(userId, targetLanguage);
    return _currentProgress!;
  }

  /// 세션 시작
  Future<void> startSession() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.totalSessions++;
    _currentProgress!.updateStreak();
    await _save();
  }

  /// 세션 종료 (시간 기록)
  Future<void> endSession(int durationMinutes) async {
    if (_currentProgress == null) return;

    _currentProgress!.totalConversationMinutes += durationMinutes;
    _currentProgress!.todayConversationMinutes += durationMinutes;
    
    // 평균 세션 시간 업데이트
    final total = _currentProgress!.totalSessions;
    if (total > 0) {
      _currentProgress!.avgSessionMinutes = 
          _currentProgress!.totalConversationMinutes / total;
    }
    
    await _save();
  }

  // ==================== 단어 ====================

  /// 단어 학습 기록
  Future<void> recordWordLearned() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.learnedWords++;
    _currentProgress!.todayWords++;
    _currentProgress!.updatedAt = DateTime.now();
    
    // 초급이면 작은 성공 기록 (도파민!)
    if (_currentProgress!.currentLevel == LearningLevel.beginner) {
      _currentProgress!.recordSmallWin();
    }
    
    await _save();
  }

  /// 단어 마스터 기록
  Future<void> recordWordMastered() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.masteredWords++;
    _currentProgress!.updatedAt = DateTime.now();
    
    // 레벨업 체크
    await _checkLevelUp();
    await _save();
  }

  // ==================== 문법 ====================

  /// 문법 패턴 학습 기록
  Future<void> recordPatternLearned() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.learnedPatterns++;
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  /// 문법 패턴 마스터 기록
  Future<void> recordPatternMastered() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.masteredPatterns++;
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  // ==================== 롤플레이 ====================

  /// 시나리오 시작
  Future<void> startScenario(String scenarioId) async {
    if (_currentProgress == null) return;
    
    _currentProgress!.currentScenarioId = scenarioId;
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  /// 시나리오 완료
  Future<void> completeScenario() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.completedScenarios++;
    _currentProgress!.currentScenarioId = null;
    _currentProgress!.updatedAt = DateTime.now();
    
    // 작은 성공! (초급 아니어도 시나리오 완료는 큰 성취)
    _currentProgress!.recordSmallWin();
    
    await _save();
  }

  // ==================== 점수 ====================

  /// 발음 점수 업데이트
  Future<void> updatePronunciationScore(double score) async {
    if (_currentProgress == null) return;
    
    // 이동 평균으로 부드럽게 업데이트
    final old = _currentProgress!.pronunciationScore;
    _currentProgress!.pronunciationScore = (old * 0.7) + (score * 0.3);
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  /// 문법 정확도 업데이트
  Future<void> updateGrammarAccuracy(double accuracy) async {
    if (_currentProgress == null) return;
    
    final old = _currentProgress!.grammarAccuracy;
    _currentProgress!.grammarAccuracy = (old * 0.7) + (accuracy * 0.3);
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  /// 유창성 점수 업데이트
  Future<void> updateFluencyScore(double score) async {
    if (_currentProgress == null) return;
    
    final old = _currentProgress!.fluencyScore;
    _currentProgress!.fluencyScore = (old * 0.7) + (score * 0.3);
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  // ==================== 칭찬 (초급용) ====================

  /// 칭찬 기록
  Future<void> recordEncouragement() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.encouragementCount++;
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  // ==================== 레벨 ====================

  /// 레벨업 체크 및 실행
  Future<bool> _checkLevelUp() async {
    if (_currentProgress == null) return false;
    
    if (_currentProgress!.readyForLevelUp) {
      final current = _currentProgress!.currentLevel;
      LearningLevel? next;
      
      switch (current) {
        case LearningLevel.beginner:
          next = LearningLevel.intermediate;
          break;
        case LearningLevel.intermediate:
          next = LearningLevel.advanced;
          break;
        case LearningLevel.advanced:
          next = LearningLevel.expert;
          break;
        case LearningLevel.expert:
          next = null; // 최고 레벨
          break;
      }
      
      if (next != null) {
        _currentProgress!.currentLevel = next;
        return true;
      }
    }
    return false;
  }

  /// 현재 레벨
  LearningLevel get currentLevel => 
      _currentProgress?.currentLevel ?? LearningLevel.beginner;

  /// 레벨업 준비 됐는지
  bool get isReadyForLevelUp => _currentProgress?.readyForLevelUp ?? false;

  // ==================== 통계 ====================

  /// 오늘 학습 요약
  Map<String, dynamic> getTodaySummary() {
    if (_currentProgress == null) {
      return {
        'words': 0,
        'minutes': 0,
        'studied': false,
      };
    }
    
    return {
      'words': _currentProgress!.todayWords,
      'minutes': _currentProgress!.todayConversationMinutes,
      'studied': _currentProgress!.studiedToday,
      'streak': _currentProgress!.streakDays,
    };
  }

  /// 전체 통계
  Map<String, dynamic> getOverallStats() {
    if (_currentProgress == null) {
      return {};
    }
    
    return {
      'level': _currentProgress!.currentLevel.displayName,
      'levelEmoji': _currentProgress!.currentLevel.emoji,
      'totalWords': _currentProgress!.learnedWords,
      'masteredWords': _currentProgress!.masteredWords,
      'totalMinutes': _currentProgress!.totalConversationMinutes,
      'scenarios': _currentProgress!.completedScenarios,
      'streak': _currentProgress!.streakDays,
      'overallScore': _currentProgress!.overallScore.toStringAsFixed(1),
      'smallWins': _currentProgress!.smallWins,
    };
  }

  /// 하루 리셋 (자정에 호출)
  Future<void> resetDaily() async {
    if (_currentProgress == null) return;
    
    _currentProgress!.todayWords = 0;
    _currentProgress!.todayConversationMinutes = 0;
    _currentProgress!.updatedAt = DateTime.now();
    await _save();
  }

  // ==================== 저장 ====================

  Future<void> _save() async {
    if (_currentProgress != null) {
      await _repository.saveProgress(_currentProgress!);
    }
  }
}
