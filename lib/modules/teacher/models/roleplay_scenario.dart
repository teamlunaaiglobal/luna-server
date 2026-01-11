import 'learning_level.dart';
import 'learning_content.dart';

/// 롤플레이 시나리오 모델
/// 유저 = 주인공
/// Luna = 다른 캐릭터들
/// 결말도 자유롭게 바꿈 → 학습인 줄 모르고 학습
class RoleplayScenario {
  final String id;
  final String title;

  /// 원본 콘텐츠 (영화/드라마/소설 등)
  final String? sourceContentId;
  final ContentType contentType;

  /// 시나리오 설명
  final String description;

  /// 배경 설정
  final String setting;

  /// 등장인물들
  final List<Character> characters;

  /// 유저가 맡을 캐릭터 ID
  final String userCharacterId;

  /// 시나리오 장면들
  final List<SceneNode> scenes;

  /// 현재 장면 인덱스
  int currentSceneIndex;

  /// 적합 레벨
  final LearningLevel recommendedLevel;

  /// 학습 목표 언어
  final String targetLanguage;

  /// 핵심 표현들 (이 시나리오에서 배울 것들)
  final List<String> keyPhrases;

  /// 문화적 맥락
  final String? culturalContext;

  /// 예상 소요 시간 (분)
  final int estimatedMinutes;

  /// 완료 여부
  bool isCompleted;

  /// 유저가 선택한 결말
  String? chosenEnding;

  /// 생성일
  final DateTime createdAt;

  RoleplayScenario({
    required this.id,
    required this.title,
    this.sourceContentId,
    required this.contentType,
    required this.description,
    required this.setting,
    required this.characters,
    required this.userCharacterId,
    required this.scenes,
    this.currentSceneIndex = 0,
    required this.recommendedLevel,
    required this.targetLanguage,
    this.keyPhrases = const [],
    this.culturalContext,
    this.estimatedMinutes = 10,
    this.isCompleted = false,
    this.chosenEnding,
    required this.createdAt,
  });

  /// 유저 캐릭터
  Character get userCharacter =>
      characters.firstWhere((c) => c.id == userCharacterId);

  /// Luna가 맡을 캐릭터들
  List<Character> get lunaCharacters =>
      characters.where((c) => c.id != userCharacterId).toList();

  /// 현재 장면
  SceneNode? get currentScene =>
      currentSceneIndex < scenes.length ? scenes[currentSceneIndex] : null;

  /// 다음 장면으로
  bool nextScene() {
    if (currentSceneIndex < scenes.length - 1) {
      currentSceneIndex++;
      return true;
    }
    return false;
  }

  /// 진행률 (0.0 ~ 1.0)
  double get progress =>
      scenes.isEmpty ? 0.0 : (currentSceneIndex + 1) / scenes.length;

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sourceContentId': sourceContentId,
        'contentType': contentType.name,
        'description': description,
        'setting': setting,
        'characters': characters.map((c) => c.toJson()).toList(),
        'userCharacterId': userCharacterId,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'currentSceneIndex': currentSceneIndex,
        'recommendedLevel': recommendedLevel.name,
        'targetLanguage': targetLanguage,
        'keyPhrases': keyPhrases,
        'culturalContext': culturalContext,
        'estimatedMinutes': estimatedMinutes,
        'isCompleted': isCompleted,
        'chosenEnding': chosenEnding,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoleplayScenario.fromJson(Map<String, dynamic> json) =>
      RoleplayScenario(
        id: json['id'] as String,
        title: json['title'] as String,
        sourceContentId: json['sourceContentId'] as String?,
        contentType: ContentType.values.byName(json['contentType'] as String),
        description: json['description'] as String,
        setting: json['setting'] as String,
        characters: (json['characters'] as List)
            .map((c) => Character.fromJson(c as Map<String, dynamic>))
            .toList(),
        userCharacterId: json['userCharacterId'] as String,
        scenes: (json['scenes'] as List)
            .map((s) => SceneNode.fromJson(s as Map<String, dynamic>))
            .toList(),
        currentSceneIndex: json['currentSceneIndex'] as int? ?? 0,
        recommendedLevel:
            LearningLevel.values.byName(json['recommendedLevel'] as String),
        targetLanguage: json['targetLanguage'] as String,
        keyPhrases: List<String>.from(json['keyPhrases'] ?? []),
        culturalContext: json['culturalContext'] as String?,
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
        isCompleted: json['isCompleted'] as bool? ?? false,
        chosenEnding: json['chosenEnding'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 등장인물
class Character {
  final String id;
  final String name;
  final String description;

  /// 성격 (Luna가 연기할 때 참고)
  final String personality;

  /// 말투 스타일
  final String speakingStyle;

  /// 프로필 이미지 URL
  final String? imageUrl;

  Character({
    required this.id,
    required this.name,
    required this.description,
    required this.personality,
    required this.speakingStyle,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'personality': personality,
        'speakingStyle': speakingStyle,
        'imageUrl': imageUrl,
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        personality: json['personality'] as String,
        speakingStyle: json['speakingStyle'] as String,
        imageUrl: json['imageUrl'] as String?,
      );
}

/// 장면 노드 (분기 가능)
class SceneNode {
  final String id;

  /// 장면 설명 (상황)
  final String situation;

  /// Luna 캐릭터 대사 (유저에게 먼저 말함)
  final String? lunaLine;

  /// Luna가 맡은 캐릭터 ID
  final String? lunaCharacterId;

  /// 유저 예상 대사 (가이드용, 강제 아님)
  final String? suggestedUserLine;

  /// 핵심 표현 (이 장면에서 배울 것)
  final List<String> keyExpressions;

  /// 선택지 (분기)
  final List<SceneChoice>? choices;

  /// 다음 장면 ID (선택지 없을 때)
  final String? nextSceneId;

  /// 장면 완료 여부
  bool isCompleted;

  /// 유저 실제 응답
  String? userResponse;

  SceneNode({
    required this.id,
    required this.situation,
    this.lunaLine,
    this.lunaCharacterId,
    this.suggestedUserLine,
    this.keyExpressions = const [],
    this.choices,
    this.nextSceneId,
    this.isCompleted = false,
    this.userResponse,
  });

  /// 분기가 있는지
  bool get hasBranch => choices != null && choices!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'situation': situation,
        'lunaLine': lunaLine,
        'lunaCharacterId': lunaCharacterId,
        'suggestedUserLine': suggestedUserLine,
        'keyExpressions': keyExpressions,
        'choices': choices?.map((c) => c.toJson()).toList(),
        'nextSceneId': nextSceneId,
        'isCompleted': isCompleted,
        'userResponse': userResponse,
      };

  factory SceneNode.fromJson(Map<String, dynamic> json) => SceneNode(
        id: json['id'] as String,
        situation: json['situation'] as String,
        lunaLine: json['lunaLine'] as String?,
        lunaCharacterId: json['lunaCharacterId'] as String?,
        suggestedUserLine: json['suggestedUserLine'] as String?,
        keyExpressions: List<String>.from(json['keyExpressions'] ?? []),
        choices: json['choices'] != null
            ? (json['choices'] as List)
                .map((c) => SceneChoice.fromJson(c as Map<String, dynamic>))
                .toList()
            : null,
        nextSceneId: json['nextSceneId'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        userResponse: json['userResponse'] as String?,
      );
}

/// 장면 선택지 (분기점)
class SceneChoice {
  final String id;

  /// 선택지 텍스트
  final String text;

  /// 이 선택 시 다음 장면 ID
  final String nextSceneId;

  /// 결말 타입 (엔딩 장면일 경우)
  final String? endingType;

  SceneChoice({
    required this.id,
    required this.text,
    required this.nextSceneId,
    this.endingType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'nextSceneId': nextSceneId,
        'endingType': endingType,
      };

  factory SceneChoice.fromJson(Map<String, dynamic> json) => SceneChoice(
        id: json['id'] as String,
        text: json['text'] as String,
        nextSceneId: json['nextSceneId'] as String,
        endingType: json['endingType'] as String?,
      );
}
