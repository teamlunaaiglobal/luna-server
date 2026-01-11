import '../models/learning_level.dart';
import 'progress_tracker.dart';
import 'grammar_helper.dart';
import 'pronunciation_coach.dart';

/// 대화 주제
enum ConversationTopic {
  freeChat,
  dailyLife,
  travel,
  food,
  hobby,
  work,
  news,
  culture,
  custom,
}

extension ConversationTopicExtension on ConversationTopic {
  String get displayName {
    switch (this) {
      case ConversationTopic.freeChat:
        return '자유 대화';
      case ConversationTopic.dailyLife:
        return '일상';
      case ConversationTopic.travel:
        return '여행';
      case ConversationTopic.food:
        return '음식';
      case ConversationTopic.hobby:
        return '취미';
      case ConversationTopic.work:
        return '일/직장';
      case ConversationTopic.news:
        return '뉴스/시사';
      case ConversationTopic.culture:
        return '문화';
      case ConversationTopic.custom:
        return '사용자 지정';
    }
  }

  String get emoji {
    switch (this) {
      case ConversationTopic.freeChat:
        return '💬';
      case ConversationTopic.dailyLife:
        return '🏠';
      case ConversationTopic.travel:
        return '✈️';
      case ConversationTopic.food:
        return '🍔';
      case ConversationTopic.hobby:
        return '🎮';
      case ConversationTopic.work:
        return '💼';
      case ConversationTopic.news:
        return '📰';
      case ConversationTopic.culture:
        return '🎭';
      case ConversationTopic.custom:
        return '✨';
    }
  }

  /// 레벨별 적합 여부
  bool isSuitableFor(LearningLevel level) {
    switch (this) {
      case ConversationTopic.freeChat:
      case ConversationTopic.dailyLife:
      case ConversationTopic.food:
      case ConversationTopic.hobby:
        return true; // 모든 레벨
      case ConversationTopic.travel:
      case ConversationTopic.work:
        return level.value >= LearningLevel.intermediate.value;
      case ConversationTopic.news:
      case ConversationTopic.culture:
        return level.value >= LearningLevel.advanced.value;
      case ConversationTopic.custom:
        return true;
    }
  }
}

/// 대화 메시지
class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? correction;
  final String? feedback;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.correction,
    this.feedback,
  });
}

/// 대화 세션
class ConversationSession {
  final String id;
  final String targetLanguage;
  final LearningLevel level;
  final ConversationTopic topic;
  final List<ConversationMessage> messages;
  final DateTime startedAt;
  DateTime? endedAt;

  ConversationSession({
    required this.id,
    required this.targetLanguage,
    required this.level,
    required this.topic,
    this.messages = const [],
    required this.startedAt,
    this.endedAt,
  });

  int get messageCount => messages.length;

  int get durationMinutes {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt).inMinutes;
  }
}

/// 프리토킹 파트너
/// Luna = 대화 친구 (선생 아님!)
class ConversationPartner {
  final ProgressTracker _progressTracker = ProgressTracker();
  final GrammarHelper _grammarHelper = GrammarHelper();
  final PronunciationCoach _pronunciationCoach = PronunciationCoach();

  /// 싱글톤
  static final ConversationPartner _instance = ConversationPartner._internal();
  factory ConversationPartner() => _instance;
  ConversationPartner._internal();

  /// 현재 세션
  ConversationSession? _currentSession;

  /// AI 호출 콜백
  Future<String> Function(String prompt)? _aiCallback;

  /// AI 콜백 설정
  void setAICallback(Future<String> Function(String prompt) callback) {
    _aiCallback = callback;
  }

  /// 현재 세션
  ConversationSession? get currentSession => _currentSession;

  /// 대화 중인지
  bool get isActive => _currentSession != null && _currentSession!.endedAt == null;

  // ==================== 세션 관리 ====================

  /// 대화 시작
  Future<ConversationSession> startConversation({
    required String targetLanguage,
    required LearningLevel level,
    ConversationTopic topic = ConversationTopic.freeChat,
  }) async {
    final now = DateTime.now();

    _currentSession = ConversationSession(
      id: 'conv_${now.millisecondsSinceEpoch}',
      targetLanguage: targetLanguage,
      level: level,
      topic: topic,
      messages: [],
      startedAt: now,
    );

    await _progressTracker.startSession();

    return _currentSession!;
  }

  /// 대화 종료
  Future<Map<String, dynamic>> endConversation() async {
    if (_currentSession == null) return {};

    _currentSession!.endedAt = DateTime.now();

    await _progressTracker.endSession(_currentSession!.durationMinutes);

    // 세션 요약
    final summary = await _generateSessionSummary();

    final session = _currentSession!;
    _currentSession = null;

    return {
      'duration': session.durationMinutes,
      'messageCount': session.messageCount,
      'summary': summary,
    };
  }

  // ==================== 대화 진행 ====================

  /// 대화 시작 인사
  Future<String> getGreeting() async {
    if (_currentSession == null) return '';

    final level = _currentSession!.level;
    final topic = _currentSession!.topic;
    final lang = _currentSession!.targetLanguage;

    if (_aiCallback != null) {
      final prompt = """
언어: $lang
레벨: ${level.displayName}
주제: ${topic.displayName}

대화 친구로서 인사해줘.
${_getLevelInstruction(level)}
""";
      return await _aiCallback!(prompt);
    }

    return _getDefaultGreeting(level);
  }

  /// 유저 메시지 처리 + Luna 응답
  Future<String> chat(String userMessage) async {
    if (_currentSession == null) return '';

    // 유저 메시지 저장
    _currentSession!.messages.add(ConversationMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Luna 응답 생성
    final response = await _generateResponse(userMessage);

    // Luna 메시지 저장
    _currentSession!.messages.add(ConversationMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    return response;
  }

  /// 응답 생성
  Future<String> _generateResponse(String userMessage) async {
    if (_aiCallback == null) return _getDefaultResponse();

    final session = _currentSession!;
    final recentContext = _getRecentContext();

    final prompt = """
언어: ${session.targetLanguage}
레벨: ${session.level.displayName}
주제: ${session.topic.displayName}

최근 대화:
$recentContext

유저: "$userMessage"

${_getLevelInstruction(session.level)}
대화 친구로서 자연스럽게 답해줘.
""";

    return await _aiCallback!(prompt);
  }

  // ==================== 피드백 (숨은 학습) ====================

  /// 자연스러운 교정 (대화 흐름 안에서)
  Future<String?> getSubtleCorrection(String userMessage) async {
    if (_currentSession == null) return null;

    final level = _currentSession!.level;

    // 초급은 교정 최소화
    if (level == LearningLevel.beginner) return null;

    // 문법 체크
    final corrections = await _grammarHelper.analyzeText(
      text: userMessage,
      targetLanguage: _currentSession!.targetLanguage,
      level: level,
    );

    if (corrections.isEmpty) return null;

    // 대화 안에서 자연스럽게 교정
    if (_aiCallback != null) {
      final prompt = """
유저가 "$userMessage"라고 했는데,
"${corrections.first.corrected}"가 더 자연스러워.

대화 흐름을 끊지 않으면서 자연스럽게 올바른 표현을 보여줘.
예: "아 맞아, [올바른 표현]! 그러고 보니..."
선생님처럼 하지 말고 친구처럼.
""";
      return await _aiCallback!(prompt);
    }

    return null;
  }

  /// 세션 끝에 요약 피드백
  Future<String> _generateSessionSummary() async {
    if (_currentSession == null) return '';

    final session = _currentSession!;

    if (_aiCallback != null) {
      final allMessages = session.messages
          .map((m) => "${m.isUser ? '유저' : 'Luna'}: ${m.text}")
          .join('\n');

      final prompt = """
대화 요약해줘:
$allMessages

레벨: ${session.level.displayName}

포함할 것:
- 잘한 점 (칭찬)
- 배운 표현들
- 다음에 연습하면 좋을 것

${session.level == LearningLevel.beginner ? '칭찬 위주로!' : ''}
친근하게 써줘.
""";

      return await _aiCallback!(prompt);
    }

    return "오늘 대화 수고했어요! 👏";
  }

  // ==================== 주제 제안 ====================

  /// 레벨에 맞는 주제 추천
  List<ConversationTopic> getRecommendedTopics(LearningLevel level) {
    return ConversationTopic.values
        .where((t) => t.isSuitableFor(level))
        .toList();
  }

  /// 대화 중 새 주제 제안
  Future<String> suggestNewTopic() async {
    if (_currentSession == null) return '';

    final level = _currentSession!.level;
    final currentTopic = _currentSession!.topic;

    if (_aiCallback != null) {
      final prompt = """
지금 ${currentTopic.displayName} 주제로 대화 중이야.
레벨: ${level.displayName}

자연스럽게 다른 주제로 넘어가는 말 해줘.
예: "그러고 보니, 요즘 뭐 하고 지내?"
""";
      return await _aiCallback!(prompt);
    }

    return "다른 얘기도 해볼까?";
  }

  // ==================== 헬퍼 ====================

  String _getLevelInstruction(LearningLevel level) {
    switch (level) {
      case LearningLevel.beginner:
        return "아주 쉬운 단어, 짧은 문장. 천천히. 칭찬 많이.";
      case LearningLevel.intermediate:
        return "일상적인 표현. 자연스럽게.";
      case LearningLevel.advanced:
        return "다양한 표현과 숙어 사용.";
      case LearningLevel.expert:
        return "고급 어휘, 복잡한 문장, 뉘앙스 포함.";
    }
  }

  String _getRecentContext() {
    if (_currentSession == null) return '';

    final recent = _currentSession!.messages.reversed.take(6).toList().reversed;
    return recent
        .map((m) => "${m.isUser ? '유저' : 'Luna'}: ${m.text}")
        .join('\n');
  }

  String _getDefaultGreeting(LearningLevel level) {
    if (level == LearningLevel.beginner) {
      return "Hi! 😊";
    }
    return "Hey! How's it going?";
  }

  String _getDefaultResponse() {
    final responses = [
      "That's interesting!",
      "Tell me more!",
      "Oh really?",
      "I see!",
    ];
    responses.shuffle();
    return responses.first;
  }
}
