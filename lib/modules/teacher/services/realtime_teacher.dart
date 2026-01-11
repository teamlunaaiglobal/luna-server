import '../models/learning_level.dart';

/// 실시간 학습 모드
enum RealtimeMode {
  /// 사물 인식 (카메라로 보는 것 학습)
  objectRecognition,
  /// 텍스트 인식 (간판, 메뉴 등)
  textRecognition,
  /// 상황 설명 (현재 상황을 외국어로)
  situationDescription,
}

/// 인식된 객체
class RecognizedObject {
  final String label;
  final String? translation;
  final String? pronunciation;
  final double confidence;
  final String? exampleSentence;

  RecognizedObject({
    required this.label,
    this.translation,
    this.pronunciation,
    required this.confidence,
    this.exampleSentence,
  });
}

/// 인식된 텍스트
class RecognizedText {
  final String text;
  final String? translation;
  final String? explanation;

  RecognizedText({
    required this.text,
    this.translation,
    this.explanation,
  });
}

/// 실시간 교재
/// 카메라로 보는 실시간 현실 = 교재
class RealtimeTeacher {
  /// 싱글톤
  static final RealtimeTeacher _instance = RealtimeTeacher._internal();
  factory RealtimeTeacher() => _instance;
  RealtimeTeacher._internal();

  /// 현재 모드
  RealtimeMode _currentMode = RealtimeMode.objectRecognition;

  /// 학습 언어
  String _targetLanguage = 'en';

  /// 학습 레벨
  LearningLevel _level = LearningLevel.beginner;

  /// AI 호출 콜백 (이미지 분석)
  Future<Map<String, dynamic>> Function(String prompt, String? imagePath)? _aiCallback;

  /// AI 콜백 설정
  void setAICallback(
    Future<Map<String, dynamic>> Function(String prompt, String? imagePath) callback,
  ) {
    _aiCallback = callback;
  }

  /// 설정
  void configure({
    required String targetLanguage,
    required LearningLevel level,
  }) {
    _targetLanguage = targetLanguage;
    _level = level;
  }

  /// 모드 변경
  void setMode(RealtimeMode mode) {
    _currentMode = mode;
  }

  RealtimeMode get currentMode => _currentMode;

  // ==================== 사물 인식 ====================

  /// 카메라 이미지에서 사물 인식
  Future<List<RecognizedObject>> recognizeObjects(String imagePath) async {
    if (_aiCallback == null) return [];

    final prompt = '''
이 이미지에서 보이는 사물들을 $_targetLanguage로 알려줘.
학습자 레벨: ${_level.displayName}

각 사물에 대해:
- label: $_targetLanguage 단어
- translation: 한국어 뜻
- pronunciation: 발음 (있다면)
- exampleSentence: 간단한 예문 (레벨에 맞게)

${_level == LearningLevel.beginner ? '초급이니까 쉬운 단어 위주로, 3개 이하로.' : ''}
''';

    final result = await _aiCallback!(prompt, imagePath);
    return _parseObjects(result);
  }

  /// 특정 사물 집중 학습
  Future<Map<String, dynamic>> focusOnObject({
    required String imagePath,
    required String objectName,
  }) async {
    if (_aiCallback == null) return {};

    final prompt = '''
이 이미지에서 "$objectName"에 대해 자세히 알려줘.
학습 언어: $_targetLanguage
레벨: ${_level.displayName}

- 단어
- 발음
- 관련 표현들
- 실생활 예문
''';

    return await _aiCallback!(prompt, imagePath);
  }

  // ==================== 텍스트 인식 ====================

  /// 이미지에서 텍스트 인식 (간판, 메뉴 등)
  Future<List<RecognizedText>> recognizeText(String imagePath) async {
    if (_aiCallback == null) return [];

    final prompt = '''
이 이미지에서 보이는 텍스트를 읽고 설명해줘.
학습 언어: $_targetLanguage
레벨: ${_level.displayName}

각 텍스트에 대해:
- text: 원본 텍스트
- translation: 번역
- explanation: 설명 (필요하면)

${_level == LearningLevel.beginner ? '쉽게 설명해줘.' : ''}
''';

    final result = await _aiCallback!(prompt, imagePath);
    return _parseTexts(result);
  }

  // ==================== 상황 설명 ====================

  /// 현재 상황을 외국어로 설명
  Future<String> describeCurrentSituation(String imagePath) async {
    if (_aiCallback == null) return '';

    final prompt = '''
이 이미지의 상황을 $_targetLanguage로 설명해줘.
레벨: ${_level.displayName}

${_getLevelInstruction()}
''';

    final result = await _aiCallback!(prompt, imagePath);
    return result['description'] as String? ?? '';
  }

  /// 상황 기반 대화 시작
  Future<String> startSituationConversation(String imagePath) async {
    if (_aiCallback == null) return '';

    final prompt = '''
이 이미지 상황에서 일어날 수 있는 대화를 시작해줘.
언어: $_targetLanguage
레벨: ${_level.displayName}

친근하게 대화 시작해줘.
${_level == LearningLevel.beginner ? '아주 쉬운 문장으로.' : ''}
''';

    final result = await _aiCallback!(prompt, imagePath);
    return result['conversation'] as String? ?? '';
  }

  // ==================== 학습 게임 ====================

  /// "이게 뭐야?" 게임 (초급용)
  Future<Map<String, dynamic>> playWhatIsThis(String imagePath) async {
    if (_aiCallback == null) return {};

    final prompt = '''
이 이미지에서 사물 하나를 골라서 퀴즈를 내줘.
언어: $_targetLanguage
레벨: 초급

형식:
- hint: 힌트 (쉬운 설명)
- answer: 정답 ($_targetLanguage)
- answerKorean: 정답 (한국어)
- encouragement: 맞추면 할 칭찬
''';

    return await _aiCallback!(prompt, imagePath);
  }

  /// "이걸로 문장 만들기" 게임
  Future<Map<String, dynamic>> playSentenceGame({
    required String imagePath,
    required String word,
  }) async {
    if (_aiCallback == null) return {};

    final prompt = '''
"$word"를 사용해서 이 이미지와 관련된 문장을 만드는 게임이야.
언어: $_targetLanguage
레벨: ${_level.displayName}

- exampleSentence: 예시 문장
- hint: 문장 만들기 힌트
- possibleAnswers: 가능한 답변들
''';

    return await _aiCallback!(prompt, imagePath);
  }

  // ==================== 헬퍼 ====================

  String _getLevelInstruction() {
    switch (_level) {
      case LearningLevel.beginner:
        return "아주 쉬운 단어와 짧은 문장으로. 3문장 이하.";
      case LearningLevel.intermediate:
        return "일상적인 표현으로. 5문장 정도.";
      case LearningLevel.advanced:
        return "자연스럽고 다양한 표현으로.";
      case LearningLevel.expert:
        return "고급 어휘와 복잡한 문장 구조 포함.";
    }
  }

  List<RecognizedObject> _parseObjects(Map<String, dynamic> result) {
    final objects = result['objects'];
    if (objects is! List) return [];

    return objects.map((o) {
      if (o is Map<String, dynamic>) {
        return RecognizedObject(
          label: o['label'] as String? ?? '',
          translation: o['translation'] as String?,
          pronunciation: o['pronunciation'] as String?,
          confidence: (o['confidence'] as num?)?.toDouble() ?? 1.0,
          exampleSentence: o['exampleSentence'] as String?,
        );
      }
      return RecognizedObject(label: o.toString(), confidence: 1.0);
    }).toList();
  }

  List<RecognizedText> _parseTexts(Map<String, dynamic> result) {
    final texts = result['texts'];
    if (texts is! List) return [];

    return texts.map((t) {
      if (t is Map<String, dynamic>) {
        return RecognizedText(
          text: t['text'] as String? ?? '',
          translation: t['translation'] as String?,
          explanation: t['explanation'] as String?,
        );
      }
      return RecognizedText(text: t.toString());
    }).toList();
  }
}
