import '../models/learning_level.dart';
import '../models/learning_content.dart';
import '../models/roleplay_scenario.dart';
import 'progress_tracker.dart';
import 'culture_guide.dart';

/// 롤플레이 상태
enum RoleplayState {
  /// 시작 전
  notStarted,
  /// 진행 중
  inProgress,
  /// 일시정지
  paused,
  /// 완료
  completed,
}

/// 롤플레이 턴 (대화 한 턴)
class RoleplayTurn {
  final String speakerId;
  final String speakerName;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? feedback;

  RoleplayTurn({
    required this.speakerId,
    required this.speakerName,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.feedback,
  });
}

/// 롤플레이 세션
class RoleplaySession {
  final RoleplayScenario scenario;
  final List<RoleplayTurn> turns;
  RoleplayState state;
  DateTime startedAt;
  DateTime? endedAt;

  RoleplaySession({
    required this.scenario,
    this.turns = const [],
    this.state = RoleplayState.notStarted,
    required this.startedAt,
    this.endedAt,
  });

  /// 진행 시간 (분)
  int get durationMinutes {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt).inMinutes;
  }
}

/// 롤플레이 엔진
/// 유저 = 주인공, Luna = 다른 캐릭터들
/// 결말도 자유롭게 바꿈 → 학습인 줄 모르고 학습
class RoleplayEngine {
  final ProgressTracker _progressTracker = ProgressTracker();
  final CultureGuide _cultureGuide = CultureGuide();

  /// 싱글톤
  static final RoleplayEngine _instance = RoleplayEngine._internal();
  factory RoleplayEngine() => _instance;
  RoleplayEngine._internal();

  /// 현재 세션
  RoleplaySession? _currentSession;

  /// AI 호출 콜백 (Luna 대사 생성)
  Future<String> Function(String prompt)? _aiCallback;

  /// AI 콜백 설정
  void setAICallback(Future<String> Function(String prompt) callback) {
    _aiCallback = callback;
  }

  /// 현재 세션 가져오기
  RoleplaySession? get currentSession => _currentSession;

  /// 진행 중인지
  bool get isActive => _currentSession?.state == RoleplayState.inProgress;

  // ==================== 세션 관리 ====================

  /// 롤플레이 시작
  Future<RoleplaySession> startSession(RoleplayScenario scenario) async {
    _currentSession = RoleplaySession(
      scenario: scenario,
      turns: [],
      state: RoleplayState.inProgress,
      startedAt: DateTime.now(),
    );

    await _progressTracker.startScenario(scenario.id);

    return _currentSession!;
  }

  /// 롤플레이 일시정지
  void pauseSession() {
    if (_currentSession != null) {
      _currentSession!.state = RoleplayState.paused;
    }
  }

  /// 롤플레이 재개
  void resumeSession() {
    if (_currentSession != null) {
      _currentSession!.state = RoleplayState.inProgress;
    }
  }

  /// 롤플레이 종료
  Future<void> endSession() async {
    if (_currentSession == null) return;

    _currentSession!.state = RoleplayState.completed;
    _currentSession!.endedAt = DateTime.now();
    _currentSession!.scenario.isCompleted = true;

    await _progressTracker.completeScenario();
    await _progressTracker.endSession(_currentSession!.durationMinutes);
  }

  // ==================== 대화 진행 ====================

  /// Luna 첫 대사 (장면 시작)
  Future<String> getOpeningLine() async {
    if (_currentSession == null) return '';

    final scenario = _currentSession!.scenario;
    final scene = scenario.currentScene;
    if (scene == null) return '';

    // Luna 캐릭터 찾기
    final lunaChar = scene.lunaCharacterId != null
        ? scenario.characters.where((c) => c.id == scene.lunaCharacterId).firstOrNull
        : scenario.lunaCharacters.firstOrNull;

    if (lunaChar == null) return scene.situation;

    // AI로 자연스러운 대사 생성
    if (_aiCallback != null && scene.lunaLine != null) {
      final prompt = _buildLunaPrompt(
        character: lunaChar,
        situation: scene.situation,
        suggestedLine: scene.lunaLine!,
        level: scenario.recommendedLevel,
      );
      return await _aiCallback!(prompt);
    }

    return scene.lunaLine ?? scene.situation;
  }

  /// 유저 응답 처리
  Future<String> processUserResponse(String userText) async {
    if (_currentSession == null) return '';

    final scenario = _currentSession!.scenario;
    final scene = scenario.currentScene;
    if (scene == null) return '';

    // 유저 턴 기록
    _currentSession!.turns.add(RoleplayTurn(
      speakerId: scenario.userCharacterId,
      speakerName: scenario.userCharacter.name,
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // 장면 완료 처리
    scene.isCompleted = true;
    scene.userResponse = userText;

    // 다음 장면으로
    if (scenario.nextScene()) {
      return await getOpeningLine();
    } else {
      // 시나리오 종료
      await endSession();
      return _getEndingMessage(scenario.recommendedLevel);
    }
  }

  /// Luna 응답 생성 (자유 대화)
  Future<String> getLunaResponse({
    required String userText,
    required Character character,
  }) async {
    if (_currentSession == null) return '';

    final scenario = _currentSession!.scenario;

    final prompt = """
롤플레이 대화:
- 캐릭터: ${character.name}
- 성격: ${character.personality}
- 말투: ${character.speakingStyle}
- 상황: ${scenario.currentScene?.situation ?? scenario.setting}
- 학습자 레벨: ${scenario.recommendedLevel.displayName}

유저가 말했어:
"$userText"

${character.name}으로서 자연스럽게 대답해줘.
학습자 레벨에 맞게 어휘와 문장 복잡도 조절해.
""";

    if (_aiCallback != null) {
      final response = await _aiCallback!(prompt);

      // Luna 턴 기록
      _currentSession!.turns.add(RoleplayTurn(
        speakerId: character.id,
        speakerName: character.name,
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      return response;
    }

    return "...";
  }

  // ==================== 피드백 ====================

  /// 유저 응답에 피드백 (레벨별)
  Future<String> getFeedback({
    required String userText,
    required LearningLevel level,
  }) async {
    // 초급: 무조건 칭찬
    if (level == LearningLevel.beginner) {
      return _getBeginnerFeedback();
    }

    // 중급 이상: AI가 피드백
    if (_aiCallback != null) {
      final prompt = """
학습자 응답: "$userText"
레벨: ${level.displayName}

자연스럽게 칭찬하면서 살짝 교정해줘.
너무 선생님처럼 하지 말고 친구처럼.
""";
      return await _aiCallback!(prompt);
    }

    return "좋아요! 👍";
  }

  String _getBeginnerFeedback() {
    final messages = [
      "완벽해요! 👏",
      "잘했어요! 계속 해봐요!",
      "좋아요! 자연스러워요!",
      "바로 그거예요! 👍",
      "멋져요! 계속 가요!",
    ];
    messages.shuffle();
    return messages.first;
  }

  // ==================== 문화 힌트 ====================

  /// 현재 장면 문화 힌트
  Future<String> getCultureHint() async {
    if (_currentSession == null) return '';

    final scenario = _currentSession!.scenario;
    final scene = scenario.currentScene;
    if (scene == null) return '';

    return await _cultureGuide.getRoleplayHint(
      country: scenario.targetLanguage, // 언어로 국가 추정
      scenario: scene.situation,
      level: scenario.recommendedLevel,
    );
  }

  // ==================== 시나리오 생성 ====================

  /// 콘텐츠에서 시나리오 생성 요청
  Future<RoleplayScenario?> generateScenario({
    required LearningContent content,
    required String userCharacterName,
  }) async {
    if (_aiCallback == null) return null;
    if (!content.type.supportsRoleplay) return null;

    final prompt = """
다음 콘텐츠로 롤플레이 시나리오 만들어줘:

제목: ${content.title}
내용: ${content.originalText}
레벨: ${content.recommendedLevel.displayName}
유저 캐릭터 이름: $userCharacterName

JSON 형식으로:
- characters: 등장인물 리스트
- scenes: 장면 리스트 (situation, lunaLine, suggestedUserLine)
- setting: 배경 설명
""";
    await _aiCallback!(prompt);
    // TODO: AI 응답 파싱해서 RoleplayScenario 생성
    return null;
  }

  // ==================== 헬퍼 ====================

  String _buildLunaPrompt({
    required Character character,
    required String situation,
    required String suggestedLine,
    required LearningLevel level,
  }) {
    return """
캐릭터: ${character.name}
성격: ${character.personality}  
말투: ${character.speakingStyle}
상황: $situation
제안 대사: $suggestedLine
학습자 레벨: ${level.displayName}

이 캐릭터로서 자연스럽게 대사를 해줘.
레벨에 맞게 난이도 조절해.
""";
  }

  String _getEndingMessage(LearningLevel level) {
    if (level == LearningLevel.beginner) {
      return "완료! 정말 잘했어요! 🎉 다음에 또 해봐요!";
    }
    return "시나리오 완료! 수고했어요. 👏";
  }
}
