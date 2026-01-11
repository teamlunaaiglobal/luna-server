import '../models/learning_level.dart';
import 'progress_tracker.dart';

/// 문법 패턴 카테고리
enum GrammarCategory {
  /// 기초 문장 구조
  basicSentence,
  /// 시제
  tense,
  /// 조사/전치사
  particle,
  /// 접속사
  conjunction,
  /// 존댓말/경어
  honorific,
  /// 관용 표현
  idiom,
  /// 고급 문법
  advanced,
}

extension GrammarCategoryExtension on GrammarCategory {
  String get displayName {
    switch (this) {
      case GrammarCategory.basicSentence:
        return '기초 문장';
      case GrammarCategory.tense:
        return '시제';
      case GrammarCategory.particle:
        return '조사/전치사';
      case GrammarCategory.conjunction:
        return '접속사';
      case GrammarCategory.honorific:
        return '존댓말';
      case GrammarCategory.idiom:
        return '관용 표현';
      case GrammarCategory.advanced:
        return '고급 문법';
    }
  }

  /// 레벨별 적합 카테고리
  static List<GrammarCategory> forLevel(LearningLevel level) {
    switch (level) {
      case LearningLevel.beginner:
        return [GrammarCategory.basicSentence, GrammarCategory.particle];
      case LearningLevel.intermediate:
        return [
          GrammarCategory.basicSentence,
          GrammarCategory.tense,
          GrammarCategory.particle,
          GrammarCategory.conjunction,
        ];
      case LearningLevel.advanced:
        return [
          GrammarCategory.tense,
          GrammarCategory.conjunction,
          GrammarCategory.honorific,
          GrammarCategory.idiom,
        ];
      case LearningLevel.expert:
        return GrammarCategory.values;
    }
  }
}

/// 문법 패턴
class GrammarPattern {
  final String id;
  final String pattern;
  final String explanation;
  final String targetLanguage;
  final GrammarCategory category;
  final LearningLevel level;
  final List<String> examples;
  final List<String> exampleTranslations;
  final String? tip;
  bool isLearned;
  bool isMastered;

  GrammarPattern({
    required this.id,
    required this.pattern,
    required this.explanation,
    required this.targetLanguage,
    required this.category,
    required this.level,
    this.examples = const [],
    this.exampleTranslations = const [],
    this.tip,
    this.isLearned = false,
    this.isMastered = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pattern': pattern,
        'explanation': explanation,
        'targetLanguage': targetLanguage,
        'category': category.name,
        'level': level.name,
        'examples': examples,
        'exampleTranslations': exampleTranslations,
        'tip': tip,
        'isLearned': isLearned,
        'isMastered': isMastered,
      };

  factory GrammarPattern.fromJson(Map<String, dynamic> json) => GrammarPattern(
        id: json['id'] as String,
        pattern: json['pattern'] as String,
        explanation: json['explanation'] as String,
        targetLanguage: json['targetLanguage'] as String,
        category: GrammarCategory.values.byName(json['category'] as String),
        level: LearningLevel.values.byName(json['level'] as String),
        examples: List<String>.from(json['examples'] ?? []),
        exampleTranslations: List<String>.from(json['exampleTranslations'] ?? []),
        tip: json['tip'] as String?,
        isLearned: json['isLearned'] as bool? ?? false,
        isMastered: json['isMastered'] as bool? ?? false,
      );
}

/// 문법 교정 결과
class GrammarCorrection {
  final String original;
  final String corrected;
  final String explanation;
  final GrammarPattern? relatedPattern;
  final bool isMinorError;

  GrammarCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
    this.relatedPattern,
    this.isMinorError = false,
  });
}

/// 문법 도우미
/// 자연스러운 교정 - "공부한다" 느낌 X
class GrammarHelper {
  final ProgressTracker _progressTracker = ProgressTracker();

  /// 싱글톤
  static final GrammarHelper _instance = GrammarHelper._internal();
  factory GrammarHelper() => _instance;
  GrammarHelper._internal();

  /// 학습한 패턴 캐시
  final List<GrammarPattern> _learnedPatterns = [];

  // ==================== 문법 체크 ====================

  /// 문장 분석 (AI 호출 필요 - 여기선 인터페이스만)
  /// 실제 구현은 AI 서비스에서
  Future<List<GrammarCorrection>> analyzeText({
    required String text,
    required String targetLanguage,
    required LearningLevel level,
  }) async {
    // TODO: AI 서비스 연동
    // 여기서는 인터페이스만 정의
    return [];
  }

  /// 자연스러운 교정 피드백 생성
  String generateFeedback({
    required List<GrammarCorrection> corrections,
    required LearningLevel level,
  }) {
    if (corrections.isEmpty) {
      return _getPositiveFeedback(level);
    }

    // 초급은 부드럽게
    if (level == LearningLevel.beginner) {
      return _getBeginnerFeedback(corrections);
    }

    // 중급 이상은 직접적으로
    return _getDetailedFeedback(corrections);
  }

  String _getPositiveFeedback(LearningLevel level) {
    final messages = [
      "완벽해요! 👍",
      "아주 자연스러워요!",
      "네이티브처럼 말했어요!",
      "문법 실력이 늘었네요!",
    ];
    messages.shuffle();
    return messages.first;
  }

  String _getBeginnerFeedback(List<GrammarCorrection> corrections) {
    // 초급: 가장 중요한 것 하나만
    final main = corrections.first;
    
    if (main.isMinorError) {
      return "거의 맞았어요! 살짝만 고치면: ${main.corrected}";
    }
    
    return "좋은 시도예요! 이렇게 하면 더 자연스러워요: ${main.corrected}";
  }

  String _getDetailedFeedback(List<GrammarCorrection> corrections) {
    final buffer = StringBuffer();
    
    for (final c in corrections) {
      buffer.writeln("• ${c.original} → ${c.corrected}");
      buffer.writeln("  (${c.explanation})");
    }
    
    return buffer.toString();
  }

  // ==================== 패턴 학습 ====================

  /// 레벨에 맞는 패턴 가져오기
  List<GrammarPattern> getPatternsForLevel(LearningLevel level, String targetLanguage) {
    // TODO: 저장소에서 가져오기
    // 여기선 빈 리스트 반환
    return [];
  }

  /// 패턴 학습 완료
  Future<void> markPatternLearned(GrammarPattern pattern) async {
    pattern.isLearned = true;
    _learnedPatterns.add(pattern);
    await _progressTracker.recordPatternLearned();
  }

  /// 패턴 마스터
  Future<void> markPatternMastered(GrammarPattern pattern) async {
    pattern.isMastered = true;
    await _progressTracker.recordPatternMastered();
  }

  // ==================== 도움말 ====================

  /// 문법 팁 생성 (레벨별)
  String getGrammarTip(GrammarCategory category, LearningLevel level) {
    // 초급용 팁
    if (level == LearningLevel.beginner) {
      switch (category) {
        case GrammarCategory.basicSentence:
          return "문장 순서가 조금 달라도 괜찮아요. 천천히 익혀가요! 🌱";
        case GrammarCategory.particle:
          return "조사는 어려워요. 틀려도 의미는 통해요! 👍";
        default:
          return "하나씩 천천히 배워가요!";
      }
    }

    // 중급 이상 팁
    switch (category) {
      case GrammarCategory.tense:
        return "시제는 문맥에 따라 유연하게 사용돼요.";
      case GrammarCategory.honorific:
        return "상황에 따라 존댓말 레벨을 조절해보세요.";
      case GrammarCategory.idiom:
        return "관용 표현은 직역하면 이상해요. 통째로 외우세요!";
      default:
        return "자연스러운 표현을 위해 많이 듣고 따라해보세요.";
    }
  }

  // ==================== 점수 ====================

  /// 문법 정확도 계산
  double calculateAccuracy(String original, List<GrammarCorrection> corrections) {
    if (corrections.isEmpty) return 100.0;

    final totalChars = original.length;
    var errorChars = 0;

    for (final c in corrections) {
      errorChars += c.original.length;
    }

    final accuracy = ((totalChars - errorChars) / totalChars) * 100;
    return accuracy.clamp(0.0, 100.0);
  }

  /// 정확도 업데이트
  Future<void> updateAccuracy(double accuracy) async {
    await _progressTracker.updateGrammarAccuracy(accuracy);
  }
}
