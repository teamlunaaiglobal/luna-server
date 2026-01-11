/// 학습 레벨 정의
/// 초급에서 99% 포기 → 세심하게 튜닝 필수!
enum LearningLevel {
  /// 🔰 초급 - 제일 중요!
  /// 단어 위주, 짧은 문장, 칭찬 많이, 실수 OK
  beginner,

  /// 📗 중급
  /// 문장 구조, 일상 대화, 롤플레이 본격화
  intermediate,

  /// 📘 고급
  /// 뉘앙스/슬랭, 복잡한 문법, 토론/논쟁
  advanced,

  /// 🎓 심화
  /// 전문 용어, 비즈니스/학술, 통역/번역 수준
  expert,
}

extension LearningLevelExtension on LearningLevel {
  /// 레벨 표시 이름
  String get displayName {
    switch (this) {
      case LearningLevel.beginner:
        return '초급';
      case LearningLevel.intermediate:
        return '중급';
      case LearningLevel.advanced:
        return '고급';
      case LearningLevel.expert:
        return '심화';
    }
  }

  /// 레벨 이모지
  String get emoji {
    switch (this) {
      case LearningLevel.beginner:
        return '🔰';
      case LearningLevel.intermediate:
        return '📗';
      case LearningLevel.advanced:
        return '📘';
      case LearningLevel.expert:
        return '🎓';
    }
  }

  /// 레벨 숫자 (1~4)
  int get value {
    switch (this) {
      case LearningLevel.beginner:
        return 1;
      case LearningLevel.intermediate:
        return 2;
      case LearningLevel.advanced:
        return 3;
      case LearningLevel.expert:
        return 4;
    }
  }

  /// 난이도 범위 (1.0 ~ 10.0)
  (double min, double max) get difficultyRange {
    switch (this) {
      case LearningLevel.beginner:
        return (1.0, 3.0);
      case LearningLevel.intermediate:
        return (3.0, 5.5);
      case LearningLevel.advanced:
        return (5.5, 8.0);
      case LearningLevel.expert:
        return (8.0, 10.0);
    }
  }

  /// 초급 전용: 포기 방지 설정
  BeginnerSettings? get beginnerSettings {
    if (this != LearningLevel.beginner) return null;
    return BeginnerSettings();
  }
}

/// 초급 전용 설정 (99% 포기 방지)
class BeginnerSettings {
  /// 작은 성공 자주 (도파민)
  final bool frequentSmallWins = true;

  /// "틀려도 괜찮아" 분위기
  final bool mistakesOkay = true;

  /// 진도 천천히
  final bool slowPace = true;

  /// 좋아하는 콘텐츠만
  final bool favoriteContentOnly = true;

  /// Luna가 응원
  final bool encouragement = true;

  /// 게임처럼 (숨은 학습)
  final bool gamified = true;

  /// 퀴즈 아닌 퀴즈
  final bool hiddenQuiz = true;

  /// "공부한다" 느낌 X
  final bool noStudyFeeling = true;
}
