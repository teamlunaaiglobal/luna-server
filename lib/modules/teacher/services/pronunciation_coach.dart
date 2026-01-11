import '../models/learning_level.dart';
import 'progress_tracker.dart';

/// 발음 평가 결과
class PronunciationResult {
  /// 전체 점수 (0~100)
  final double overallScore;

  /// 정확도 (0~100)
  final double accuracy;

  /// 유창성 (0~100)
  final double fluency;

  /// 억양 (0~100)
  final double intonation;

  /// 문제 있는 부분들
  final List<PronunciationIssue> issues;

  /// 잘한 부분들
  final List<String> goodParts;

  PronunciationResult({
    required this.overallScore,
    required this.accuracy,
    required this.fluency,
    required this.intonation,
    this.issues = const [],
    this.goodParts = const [],
  });

  /// 레벨별 통과 기준
  bool isPassing(LearningLevel level) {
    switch (level) {
      case LearningLevel.beginner:
        return overallScore >= 50; // 초급은 낮게
      case LearningLevel.intermediate:
        return overallScore >= 65;
      case LearningLevel.advanced:
        return overallScore >= 75;
      case LearningLevel.expert:
        return overallScore >= 85;
    }
  }
}

/// 발음 문제점
class PronunciationIssue {
  /// 문제 있는 단어/음절
  final String segment;

  /// 사용자 발음 (추정)
  final String userPronunciation;

  /// 올바른 발음
  final String correctPronunciation;

  /// 팁
  final String? tip;

  /// 심각도 (1~3)
  final int severity;

  PronunciationIssue({
    required this.segment,
    required this.userPronunciation,
    required this.correctPronunciation,
    this.tip,
    this.severity = 1,
  });
}

/// 발음 코치
/// 발음 = 자신감이 핵심 (초급은 틀려도 OK)
class PronunciationCoach {
  final ProgressTracker _progressTracker = ProgressTracker();

  /// 싱글톤
  static final PronunciationCoach _instance = PronunciationCoach._internal();
  factory PronunciationCoach() => _instance;
  PronunciationCoach._internal();

  // ==================== 발음 평가 ====================

  /// 발음 평가 (음성 데이터 필요 - 여기선 인터페이스)
  /// 실제 구현은 STT/음성 분석 서비스에서
  Future<PronunciationResult> evaluate({
    required String expectedText,
    required String audioPath,
    required String targetLanguage,
    required LearningLevel level,
  }) async {
    // TODO: 음성 분석 서비스 연동
    // 여기서는 더미 결과 반환
    return PronunciationResult(
      overallScore: 0,
      accuracy: 0,
      fluency: 0,
      intonation: 0,
    );
  }

  /// 간단 평가 (STT 텍스트 비교)
  PronunciationResult quickEvaluate({
    required String expectedText,
    required String recognizedText,
    required LearningLevel level,
  }) {
    final expected = _normalize(expectedText);
    final recognized = _normalize(recognizedText);

    // 단순 유사도 계산
    final accuracy = _calculateSimilarity(expected, recognized) * 100;

    // 레벨별 가산점
    final levelBonus = level == LearningLevel.beginner ? 10.0 : 0.0;

    final score = (accuracy + levelBonus).clamp(0.0, 100.0);

    return PronunciationResult(
      overallScore: score,
      accuracy: accuracy,
      fluency: score, // 간단 평가에선 동일
      intonation: score,
      goodParts: accuracy > 70 ? ['전반적으로 좋아요!'] : [],
    );
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    final aWords = a.split(' ');
    final bWords = b.split(' ');

    var matches = 0;
    for (final word in aWords) {
      if (bWords.contains(word)) matches++;
    }

    return matches / aWords.length;
  }

  // ==================== 피드백 ====================

  /// 피드백 생성 (레벨별)
  String generateFeedback({
    required PronunciationResult result,
    required LearningLevel level,
  }) {
    // 초급: 무조건 칭찬 + 부드러운 제안
    if (level == LearningLevel.beginner) {
      return _generateBeginnerFeedback(result);
    }

    // 중급: 균형 잡힌 피드백
    if (level == LearningLevel.intermediate) {
      return _generateIntermediateFeedback(result);
    }

    // 고급/심화: 상세 피드백
    return _generateAdvancedFeedback(result);
  }

  String _generateBeginnerFeedback(PronunciationResult result) {
    if (result.overallScore >= 70) {
      return "와! 정말 잘했어요! 👏 발음이 아주 좋아요!";
    } else if (result.overallScore >= 50) {
      return "잘하고 있어요! 👍 조금만 더 연습하면 완벽해질 거예요!";
    } else {
      return "좋은 시도예요! 🌱 천천히 따라해보세요. 처음엔 다 이래요!";
    }
  }

  String _generateIntermediateFeedback(PronunciationResult result) {
    final buffer = StringBuffer();

    if (result.overallScore >= 80) {
      buffer.writeln("훌륭해요! 발음이 많이 좋아졌어요.");
    } else if (result.overallScore >= 60) {
      buffer.writeln("좋아요! 몇 가지만 신경 쓰면 더 좋아질 거예요.");
    } else {
      buffer.writeln("괜찮아요. 아래 부분을 연습해보세요.");
    }

    if (result.issues.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("💡 연습 포인트:");
      for (final issue in result.issues.take(2)) {
        buffer.writeln("• ${issue.segment}: ${issue.tip ?? issue.correctPronunciation}");
      }
    }

    return buffer.toString();
  }

  String _generateAdvancedFeedback(PronunciationResult result) {
    final buffer = StringBuffer();

    buffer.writeln("📊 발음 분석:");
    buffer.writeln("• 정확도: ${result.accuracy.toStringAsFixed(0)}점");
    buffer.writeln("• 유창성: ${result.fluency.toStringAsFixed(0)}점");
    buffer.writeln("• 억양: ${result.intonation.toStringAsFixed(0)}점");

    if (result.issues.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("🔍 개선 포인트:");
      for (final issue in result.issues) {
        buffer.writeln("• ${issue.segment}");
        buffer.writeln("  ${issue.userPronunciation} → ${issue.correctPronunciation}");
        if (issue.tip != null) {
          buffer.writeln("  💡 ${issue.tip}");
        }
      }
    }

    if (result.goodParts.isNotEmpty) {
      buffer.writeln("");
      buffer.writeln("✨ 잘한 부분: ${result.goodParts.join(', ')}");
    }

    return buffer.toString();
  }

  // ==================== 연습 ====================

  /// 따라하기 문장 생성 (레벨별)
  List<String> getPracticeSentences(LearningLevel level, String targetLanguage) {
    // TODO: 언어별, 레벨별 문장 데이터베이스에서 가져오기
    // 여기선 예시만
    switch (level) {
      case LearningLevel.beginner:
        return [
          "Hello", // 짧고 쉬운 것
          "Thank you",
          "Nice to meet you",
        ];
      case LearningLevel.intermediate:
        return [
          "How are you doing today?",
          "I'd like to order a coffee, please.",
          "What time does the store close?",
        ];
      case LearningLevel.advanced:
        return [
          "I've been meaning to ask you about that project.",
          "Would you mind if I borrowed your charger?",
          "The weather has been quite unpredictable lately.",
        ];
      case LearningLevel.expert:
        return [
          "Despite the unprecedented circumstances, we managed to exceed expectations.",
          "I couldn't agree more with your assessment of the situation.",
          "It's been a pleasure collaborating with such talented individuals.",
        ];
    }
  }

  /// 발음 팁 (언어별 어려운 발음)
  String getPronunciationTip(String targetLanguage, LearningLevel level) {
    // 초급용 일반 팁
    if (level == LearningLevel.beginner) {
      return "천천히, 또박또박 말해보세요. 속도보다 정확성이 중요해요! 🐢";
    }

    // 언어별 팁 (예시)
    switch (targetLanguage.toLowerCase()) {
      case 'en':
      case 'english':
        return "영어는 강세가 중요해요. 강조할 음절을 확실히 세게 발음하세요.";
      case 'ja':
      case 'japanese':
        return "일본어는 음의 길이가 중요해요. 장음과 단음을 구분하세요.";
      case 'zh':
      case 'chinese':
        return "중국어는 성조가 핵심! 4성을 정확히 구분해보세요.";
      case 'ko':
      case 'korean':
        return "한국어는 받침 발음이 어려워요. ㄱ,ㄷ,ㅂ 받침을 연습하세요.";
      default:
        return "원어민 발음을 많이 듣고 따라하는 게 최고의 연습이에요!";
    }
  }

  // ==================== 점수 업데이트 ====================

  /// 발음 점수 저장
  Future<void> saveScore(double score) async {
    await _progressTracker.updatePronunciationScore(score);
  }

  /// 유창성 점수 저장
  Future<void> saveFluencyScore(double score) async {
    await _progressTracker.updateFluencyScore(score);
  }
}
