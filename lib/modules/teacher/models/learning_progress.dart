import 'learning_level.dart';

/// 학습 진도 모델
/// 몰래 추적 - 유저는 학습인 줄 모름!
class LearningProgress {
  final String id;
  final String userId;

  /// 현재 레벨
  LearningLevel currentLevel;

  /// 목표 언어
  final String targetLanguage;

  // ===== 어휘 =====
  /// 배운 단어 수
  int learnedWords;

  /// 마스터한 단어 수
  int masteredWords;

  /// 오늘 배운 단어
  int todayWords;

  // ===== 문법 =====
  /// 배운 문법 패턴
  int learnedPatterns;

  /// 마스터한 패턴
  int masteredPatterns;

  // ===== 대화 =====
  /// 총 대화 시간 (분)
  int totalConversationMinutes;

  /// 오늘 대화 시간 (분)
  int todayConversationMinutes;

  // ===== 롤플레이 =====
  /// 완료한 시나리오 수
  int completedScenarios;

  /// 현재 진행중 시나리오
  String? currentScenarioId;

  // ===== 스트릭 =====
  /// 연속 학습일
  int streakDays;

  /// 마지막 학습일
  DateTime? lastStudyDate;

  // ===== 정확도 =====
  /// 발음 평균 점수 (0~100)
  double pronunciationScore;

  /// 문법 정확도 (0~100)
  double grammarAccuracy;

  /// 유창성 점수 (0~100)
  double fluencyScore;

  // ===== 도파민 포인트 (초급용) =====
  /// 작은 성공 횟수 (초급 포기 방지)
  int smallWins;

  /// 칭찬 받은 횟수
  int encouragementCount;

  // ===== 통계 =====
  /// 총 학습 세션 수
  int totalSessions;

  /// 평균 세션 시간 (분)
  double avgSessionMinutes;

  /// 생성일
  final DateTime createdAt;

  /// 업데이트일
  DateTime updatedAt;

  LearningProgress({
    required this.id,
    required this.userId,
    this.currentLevel = LearningLevel.beginner,
    required this.targetLanguage,
    this.learnedWords = 0,
    this.masteredWords = 0,
    this.todayWords = 0,
    this.learnedPatterns = 0,
    this.masteredPatterns = 0,
    this.totalConversationMinutes = 0,
    this.todayConversationMinutes = 0,
    this.completedScenarios = 0,
    this.currentScenarioId,
    this.streakDays = 0,
    this.lastStudyDate,
    this.pronunciationScore = 0.0,
    this.grammarAccuracy = 0.0,
    this.fluencyScore = 0.0,
    this.smallWins = 0,
    this.encouragementCount = 0,
    this.totalSessions = 0,
    this.avgSessionMinutes = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 전체 점수 (가중 평균)
  double get overallScore {
    return (pronunciationScore * 0.3) +
        (grammarAccuracy * 0.4) +
        (fluencyScore * 0.3);
  }

  /// 레벨업 준비 됐는지 체크
  bool get readyForLevelUp {
    switch (currentLevel) {
      case LearningLevel.beginner:
        // 초급 → 중급: 단어 100개, 점수 60 이상
        return masteredWords >= 100 && overallScore >= 60;
      case LearningLevel.intermediate:
        // 중급 → 고급: 단어 500개, 점수 70 이상
        return masteredWords >= 500 && overallScore >= 70;
      case LearningLevel.advanced:
        // 고급 → 심화: 단어 1000개, 점수 80 이상
        return masteredWords >= 1000 && overallScore >= 80;
      case LearningLevel.expert:
        return false; // 최고 레벨
    }
  }

  /// 오늘 학습했는지
  bool get studiedToday {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    return lastStudyDate!.year == now.year &&
        lastStudyDate!.month == now.month &&
        lastStudyDate!.day == now.day;
  }

  /// 스트릭 업데이트
  void updateStreak() {
    final now = DateTime.now();
    if (lastStudyDate == null) {
      streakDays = 1;
    } else {
      final diff = now.difference(lastStudyDate!).inDays;
      if (diff == 1) {
        streakDays++;
      } else if (diff > 1) {
        streakDays = 1; // 리셋
      }
    }
    lastStudyDate = now;
    updatedAt = now;
  }

  /// 작은 성공 기록 (초급 도파민)
  void recordSmallWin() {
    smallWins++;
    updatedAt = DateTime.now();
  }

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'currentLevel': currentLevel.name,
        'targetLanguage': targetLanguage,
        'learnedWords': learnedWords,
        'masteredWords': masteredWords,
        'todayWords': todayWords,
        'learnedPatterns': learnedPatterns,
        'masteredPatterns': masteredPatterns,
        'totalConversationMinutes': totalConversationMinutes,
        'todayConversationMinutes': todayConversationMinutes,
        'completedScenarios': completedScenarios,
        'currentScenarioId': currentScenarioId,
        'streakDays': streakDays,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'pronunciationScore': pronunciationScore,
        'grammarAccuracy': grammarAccuracy,
        'fluencyScore': fluencyScore,
        'smallWins': smallWins,
        'encouragementCount': encouragementCount,
        'totalSessions': totalSessions,
        'avgSessionMinutes': avgSessionMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      LearningProgress(
        id: json['id'] as String,
        userId: json['userId'] as String,
        currentLevel: LearningLevel.values.byName(json['currentLevel'] as String),
        targetLanguage: json['targetLanguage'] as String,
        learnedWords: json['learnedWords'] as int? ?? 0,
        masteredWords: json['masteredWords'] as int? ?? 0,
        todayWords: json['todayWords'] as int? ?? 0,
        learnedPatterns: json['learnedPatterns'] as int? ?? 0,
        masteredPatterns: json['masteredPatterns'] as int? ?? 0,
        totalConversationMinutes: json['totalConversationMinutes'] as int? ?? 0,
        todayConversationMinutes: json['todayConversationMinutes'] as int? ?? 0,
        completedScenarios: json['completedScenarios'] as int? ?? 0,
        currentScenarioId: json['currentScenarioId'] as String?,
        streakDays: json['streakDays'] as int? ?? 0,
        lastStudyDate: json['lastStudyDate'] != null
            ? DateTime.parse(json['lastStudyDate'] as String)
            : null,
        pronunciationScore: (json['pronunciationScore'] as num?)?.toDouble() ?? 0.0,
        grammarAccuracy: (json['grammarAccuracy'] as num?)?.toDouble() ?? 0.0,
        fluencyScore: (json['fluencyScore'] as num?)?.toDouble() ?? 0.0,
        smallWins: json['smallWins'] as int? ?? 0,
        encouragementCount: json['encouragementCount'] as int? ?? 0,
        totalSessions: json['totalSessions'] as int? ?? 0,
        avgSessionMinutes: (json['avgSessionMinutes'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
