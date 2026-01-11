import 'learning_level.dart';

/// 콘텐츠 타입
/// 교재 = 세상 전체!
enum ContentType {
  /// 영화/드라마 자막 + 롤플레이
  movie,
  drama,

  /// 소설/시나리오 + 주인공 역할
  novel,
  scenario,

  /// 카메라로 보는 실시간 현실
  realtime,

  /// 유저가 좋아하는 모든 콘텐츠
  youtube,
  music,
  news,
  podcast,
  webtoon,
  game,
  custom,
}

extension ContentTypeExtension on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.movie:
        return '영화';
      case ContentType.drama:
        return '드라마';
      case ContentType.novel:
        return '소설';
      case ContentType.scenario:
        return '시나리오';
      case ContentType.realtime:
        return '실시간';
      case ContentType.youtube:
        return '유튜브';
      case ContentType.music:
        return '음악';
      case ContentType.news:
        return '뉴스';
      case ContentType.podcast:
        return '팟캐스트';
      case ContentType.webtoon:
        return '웹툰';
      case ContentType.game:
        return '게임';
      case ContentType.custom:
        return '사용자 정의';
    }
  }

  String get emoji {
    switch (this) {
      case ContentType.movie:
        return '🎬';
      case ContentType.drama:
        return '📺';
      case ContentType.novel:
        return '📖';
      case ContentType.scenario:
        return '🎭';
      case ContentType.realtime:
        return '📷';
      case ContentType.youtube:
        return '▶️';
      case ContentType.music:
        return '🎵';
      case ContentType.news:
        return '📰';
      case ContentType.podcast:
        return '🎙️';
      case ContentType.webtoon:
        return '📱';
      case ContentType.game:
        return '🎮';
      case ContentType.custom:
        return '✨';
    }
  }

  /// 롤플레이 가능 여부
  bool get supportsRoleplay {
    switch (this) {
      case ContentType.movie:
      case ContentType.drama:
      case ContentType.novel:
      case ContentType.scenario:
      case ContentType.game:
        return true;
      default:
        return false;
    }
  }
}

/// 학습 콘텐츠 모델
/// 콘텐츠 ≠ 언어 (중요!)
/// 오징어게임으로 한국어/일본어/스페인어 다 배울 수 있음
class LearningContent {
  final String id;
  final ContentType type;
  final String title;

  /// 원본 언어 (콘텐츠 언어)
  final String sourceLanguage;

  /// 학습 목표 언어 (배우고 싶은 언어)
  final String targetLanguage;

  /// 원본 텍스트
  final String originalText;

  /// 번역 텍스트
  final String? translatedText;

  /// 적합 레벨
  final LearningLevel recommendedLevel;

  /// 난이도 (1.0 ~ 10.0)
  final double difficulty;

  /// 핵심 단어/표현
  final List<String> keywords;

  /// 문화적 맥락 노트
  final String? culturalNote;

  /// 장면 설명 (롤플레이용)
  final String? sceneDescription;

  /// 등장인물 (롤플레이용)
  final List<String>? characters;

  /// 미디어 URL (영상/음성)
  final String? mediaUrl;

  /// 생성 시간
  final DateTime createdAt;

  /// 태그
  final List<String> tags;

  LearningContent({
    required this.id,
    required this.type,
    required this.title,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.originalText,
    this.translatedText,
    required this.recommendedLevel,
    required this.difficulty,
    this.keywords = const [],
    this.culturalNote,
    this.sceneDescription,
    this.characters,
    this.mediaUrl,
    required this.createdAt,
    this.tags = const [],
  });

  /// JSON 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'originalText': originalText,
        'translatedText': translatedText,
        'recommendedLevel': recommendedLevel.name,
        'difficulty': difficulty,
        'keywords': keywords,
        'culturalNote': culturalNote,
        'sceneDescription': sceneDescription,
        'characters': characters,
        'mediaUrl': mediaUrl,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
      };

  factory LearningContent.fromJson(Map<String, dynamic> json) =>
      LearningContent(
        id: json['id'] as String,
        type: ContentType.values.byName(json['type'] as String),
        title: json['title'] as String,
        sourceLanguage: json['sourceLanguage'] as String,
        targetLanguage: json['targetLanguage'] as String,
        originalText: json['originalText'] as String,
        translatedText: json['translatedText'] as String?,
        recommendedLevel:
            LearningLevel.values.byName(json['recommendedLevel'] as String),
        difficulty: (json['difficulty'] as num).toDouble(),
        keywords: List<String>.from(json['keywords'] ?? []),
        culturalNote: json['culturalNote'] as String?,
        sceneDescription: json['sceneDescription'] as String?,
        characters: json['characters'] != null
            ? List<String>.from(json['characters'])
            : null,
        mediaUrl: json['mediaUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        tags: List<String>.from(json['tags'] ?? []),
      );

  /// 레벨에 적합한지 체크
  bool isSuitableFor(LearningLevel level) {
    final range = level.difficultyRange;
    return difficulty >= range.$1 && difficulty <= range.$2;
  }
}
