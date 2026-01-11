import '../models/learning_level.dart';

/// 문화 카테고리
enum CultureCategory {
  greetings,
  dining,
  business,
  dailyLife,
  holidays,
  taboos,
  humor,
  gestures,
}

extension CultureCategoryExtension on CultureCategory {
  String get displayName {
    switch (this) {
      case CultureCategory.greetings:
        return '인사/예절';
      case CultureCategory.dining:
        return '식사 문화';
      case CultureCategory.business:
        return '비즈니스';
      case CultureCategory.dailyLife:
        return '일상생활';
      case CultureCategory.holidays:
        return '명절/기념일';
      case CultureCategory.taboos:
        return '금기사항';
      case CultureCategory.humor:
        return '유머/속어';
      case CultureCategory.gestures:
        return '제스처';
    }
  }

  String get emoji {
    switch (this) {
      case CultureCategory.greetings:
        return '👋';
      case CultureCategory.dining:
        return '🍽️';
      case CultureCategory.business:
        return '💼';
      case CultureCategory.dailyLife:
        return '🏠';
      case CultureCategory.holidays:
        return '🎉';
      case CultureCategory.taboos:
        return '🚫';
      case CultureCategory.humor:
        return '😄';
      case CultureCategory.gestures:
        return '🤝';
    }
  }
}

/// 문화 설명 요청
class CultureRequest {
  /// 국가 (이름 또는 코드, 자유 형식)
  final String country;

  /// 상황 설명
  final String situation;

  /// 콘텐츠 (영화/드라마 장면 등)
  final String? content;

  /// 카테고리 힌트
  final CultureCategory? category;

  /// 학습 레벨
  final LearningLevel level;

  CultureRequest({
    required this.country,
    required this.situation,
    this.content,
    this.category,
    this.level = LearningLevel.beginner,
  });

  /// AI 프롬프트용 텍스트
  String toPrompt() {
    final buffer = StringBuffer();

    buffer.writeln("국가: $country");
    buffer.writeln("상황: $situation");

    if (content != null) {
      buffer.writeln("콘텐츠: $content");
    }

    if (category != null) {
      buffer.writeln("카테고리: ${category!.displayName}");
    }

    buffer.writeln("학습자 레벨: ${level.displayName}");

    // 레벨별 톤 지시
    switch (level) {
      case LearningLevel.beginner:
        buffer.writeln("→ 쉽고 친근하게, 부담 없이 설명해줘");
        break;
      case LearningLevel.intermediate:
        buffer.writeln("→ 실용적인 팁 위주로 설명해줘");
        break;
      case LearningLevel.advanced:
      case LearningLevel.expert:
        buffer.writeln("→ 깊이 있는 문화적 맥락까지 설명해줘");
        break;
    }

    return buffer.toString();
  }
}

/// 문화 설명 응답 (AI가 생성)
class CultureResponse {
  final String explanation;
  final String? doThis;
  final String? dontDoThis;
  final String? funFact;

  CultureResponse({
    required this.explanation,
    this.doThis,
    this.dontDoThis,
    this.funFact,
  });

  factory CultureResponse.fromAIText(String text) {
    // AI 응답 텍스트 그대로 사용
    return CultureResponse(explanation: text);
  }

  factory CultureResponse.fromJson(Map<String, dynamic> json) => CultureResponse(
        explanation: json['explanation'] as String? ?? '',
        doThis: json['doThis'] as String?,
        dontDoThis: json['dontDoThis'] as String?,
        funFact: json['funFact'] as String?,
      );
}

/// 문화 가이드
/// Luna AI가 상황에 맞게 설명
class CultureGuide {
  /// 싱글톤
  static final CultureGuide _instance = CultureGuide._internal();
  factory CultureGuide() => _instance;
  CultureGuide._internal();

  /// AI 호출 콜백 (외부에서 주입)
  Future<String> Function(String prompt)? _aiCallback;

  /// AI 콜백 설정
  void setAICallback(Future<String> Function(String prompt) callback) {
    _aiCallback = callback;
  }

  /// 문화 설명 요청
  Future<CultureResponse> explain(CultureRequest request) async {
    final prompt = _buildPrompt(request);

    if (_aiCallback != null) {
      final aiResponse = await _aiCallback!(prompt);
      return CultureResponse.fromAIText(aiResponse);
    }

    // AI 없으면 기본 응답
    return CultureResponse(
      explanation: "${request.country}의 문화에 대해 알려드릴게요.",
    );
  }

  /// 콘텐츠 문화 맥락 (영화/드라마 장면)
  Future<CultureResponse> explainContent({
    required String content,
    required String country,
    required String scene,
    LearningLevel level = LearningLevel.beginner,
  }) async {
    return await explain(CultureRequest(
      country: country,
      situation: scene,
      content: content,
      level: level,
    ));
  }

  /// 롤플레이 힌트
  Future<String> getRoleplayHint({
    required String country,
    required String scenario,
    LearningLevel level = LearningLevel.beginner,
  }) async {
    final request = CultureRequest(
      country: country,
      situation: "롤플레이: $scenario",
      level: level,
    );

    final prompt = "이 상황에서 ${request.country} 사람처럼 행동하려면?\n${request.toPrompt()}";

    if (_aiCallback != null) {
      return await _aiCallback!(prompt);
    }

    return "현지인처럼 자연스럽게 해보세요!";
  }

  /// 간단 문화 팁
  String getQuickTip(String country, LearningLevel level) {
    // 간단한 팁은 AI를 호출하지 않고 미리 준비된 내용 반환
    final tips = {
      '미국': '미국에서는 보통 팁을 15-20% 정도 줍니다.',
      '일본': '일본에서는 팁을 주는 문화가 없습니다.',
      '프랑스': '프랑스에서는 서비스 요금이 포함된 경우가 많지만, 만족했다면 약간의 팁을 남기기도 합니다.',
      '기타': '나라마다 팁 문화가 다르니 미리 확인해보세요!',
    };

    if (level != LearningLevel.beginner) {
      return '현지 문화를 존중하는 것이 중요해요.';
    }

    return tips[country] ?? tips['기타']!;
  }

  /// 프롬프트 생성
  String _buildPrompt(CultureRequest request) {
    return """
문화 가이드 요청:
${request.toPrompt()}

자연스럽고 친근하게 설명해줘.
""";
  }
}
