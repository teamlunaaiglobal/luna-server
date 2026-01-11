import '../models/learning_level.dart';
import '../data/tutor_repository.dart';
import 'progress_tracker.dart';

/// 단어 상태
enum WordStatus {
  /// 처음 봄
  newWord,
  /// 학습 중
  learning,
  /// 복습 필요
  needsReview,
  /// 마스터!
  mastered,
}

/// 단어 정보
class VocabularyItem {
  final String word;
  final String meaning;
  final String? pronunciation;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String targetLanguage;
  final List<String> tags;
  WordStatus status;
  int correctCount;
  int incorrectCount;
  DateTime lastReviewed;
  DateTime createdAt;

  VocabularyItem({
    required this.word,
    required this.meaning,
    this.pronunciation,
    this.exampleSentence,
    this.exampleTranslation,
    required this.targetLanguage,
    this.tags = const [],
    this.status = WordStatus.newWord,
    this.correctCount = 0,
    this.incorrectCount = 0,
    required this.lastReviewed,
    required this.createdAt,
  });

  /// 정답률
  double get accuracy {
    final total = correctCount + incorrectCount;
    if (total == 0) return 0.0;
    return correctCount / total;
  }

  /// 마스터 조건: 정답 5회 이상, 정답률 80% 이상
  bool get shouldBeMastered => correctCount >= 5 && accuracy >= 0.8;

  Map<String, dynamic> toJson() => {
        'word': word,
        'meaning': meaning,
        'pronunciation': pronunciation,
        'exampleSentence': exampleSentence,
        'exampleTranslation': exampleTranslation,
        'targetLanguage': targetLanguage,
        'tags': tags,
        'status': status.name,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'lastReviewed': lastReviewed.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'mastered': status == WordStatus.mastered,
      };

  factory VocabularyItem.fromJson(Map<String, dynamic> json) => VocabularyItem(
        word: json['word'] as String,
        meaning: json['meaning'] as String,
        pronunciation: json['pronunciation'] as String?,
        exampleSentence: json['exampleSentence'] as String?,
        exampleTranslation: json['exampleTranslation'] as String?,
        targetLanguage: json['targetLanguage'] as String,
        tags: List<String>.from(json['tags'] ?? []),
        status: WordStatus.values.byName(json['status'] as String? ?? 'newWord'),
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        lastReviewed: DateTime.parse(json['lastReviewed'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 어휘 확장기
/// 단어 = 게임처럼 (숨은 학습)
class VocabularyBuilder {
  final TutorRepository _repository = TutorRepository();
  final ProgressTracker _progressTracker = ProgressTracker();

  /// 싱글톤
  static final VocabularyBuilder _instance = VocabularyBuilder._internal();
  factory VocabularyBuilder() => _instance;
  VocabularyBuilder._internal();

  /// 현재 유저 ID
  String? _userId;

  /// 초기화
  void initialize(String userId) {
    _userId = userId;
  }

  // ==================== 단어 추가 ====================

  /// 새 단어 추가
  Future<VocabularyItem> addWord({
    required String word,
    required String meaning,
    required String targetLanguage,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final item = VocabularyItem(
      word: word,
      meaning: meaning,
      pronunciation: pronunciation,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      targetLanguage: targetLanguage,
      tags: tags,
      lastReviewed: now,
      createdAt: now,
    );

    await _repository.saveVocabulary(_userId!, word, item.toJson());
    await _progressTracker.recordWordLearned();
    
    return item;
  }

  /// 콘텐츠에서 단어 추출해서 추가
  Future<List<VocabularyItem>> addWordsFromContent({
    required List<String> words,
    required List<String> meanings,
    required String targetLanguage,
    List<String> tags = const [],
  }) async {
    final items = <VocabularyItem>[];
    
    for (var i = 0; i < words.length && i < meanings.length; i++) {
      final item = await addWord(
        word: words[i],
        meaning: meanings[i],
        targetLanguage: targetLanguage,
        tags: tags,
      );
      items.add(item);
    }
    
    return items;
  }

  // ==================== 단어 조회 ====================

  /// 단어 조회
  Future<VocabularyItem?> getWord(String word) async {
    final data = await _repository.getVocabulary(_userId!, word);
    if (data == null) return null;
    return VocabularyItem.fromJson(data);
  }

  /// 모든 단어 조회
  Future<List<VocabularyItem>> getAllWords() async {
    final dataList = await _repository.getAllVocabulary(_userId!);
    return dataList.map((d) => VocabularyItem.fromJson(d)).toList();
  }

  /// 상태별 단어 조회
  Future<List<VocabularyItem>> getWordsByStatus(WordStatus status) async {
    final all = await getAllWords();
    return all.where((w) => w.status == status).toList();
  }

  /// 복습 필요한 단어 조회
  Future<List<VocabularyItem>> getWordsForReview() async {
    final all = await getAllWords();
    final now = DateTime.now();
    
    return all.where((w) {
      if (w.status == WordStatus.mastered) return false;
      
      // 마지막 복습 후 경과 시간에 따라
      final hoursSince = now.difference(w.lastReviewed).inHours;
      
      switch (w.status) {
        case WordStatus.newWord:
          return true; // 새 단어는 항상
        case WordStatus.learning:
          return hoursSince >= 4; // 4시간 후
        case WordStatus.needsReview:
          return hoursSince >= 24; // 24시간 후
        case WordStatus.mastered:
          return false;
      }
    }).toList();
  }

  // ==================== 퀴즈/복습 ====================

  /// 퀴즈용 단어 가져오기 (레벨에 맞게)
  Future<List<VocabularyItem>> getQuizWords({
    required LearningLevel level,
    int count = 5,
  }) async {
    final reviewWords = await getWordsForReview();
    
    // 초급은 더 적게, 쉽게
    final actualCount = level == LearningLevel.beginner 
        ? (count * 0.6).round() 
        : count;
    
    // 섞어서 반환
    reviewWords.shuffle();
    return reviewWords.take(actualCount).toList();
  }

  /// 정답 기록
  Future<void> recordCorrect(String word) async {
    final item = await getWord(word);
    if (item == null) return;

    item.correctCount++;
    item.lastReviewed = DateTime.now();
    
    // 상태 업데이트
    if (item.shouldBeMastered) {
      item.status = WordStatus.mastered;
      await _progressTracker.recordWordMastered();
    } else if (item.correctCount >= 2) {
      item.status = WordStatus.learning;
    }

    await _repository.saveVocabulary(_userId!, word, item.toJson());
  }

  /// 오답 기록
  Future<void> recordIncorrect(String word) async {
    final item = await getWord(word);
    if (item == null) return;

    item.incorrectCount++;
    item.lastReviewed = DateTime.now();
    item.status = WordStatus.needsReview;

    await _repository.saveVocabulary(_userId!, word, item.toJson());
  }

  // ==================== 통계 ====================

  /// 단어 통계
  Future<Map<String, dynamic>> getStats() async {
    final all = await getAllWords();
    
    final newCount = all.where((w) => w.status == WordStatus.newWord).length;
    final learningCount = all.where((w) => w.status == WordStatus.learning).length;
    final reviewCount = all.where((w) => w.status == WordStatus.needsReview).length;
    final masteredCount = all.where((w) => w.status == WordStatus.mastered).length;
    
    return {
      'total': all.length,
      'new': newCount,
      'learning': learningCount,
      'needsReview': reviewCount,
      'mastered': masteredCount,
      'masteryRate': all.isEmpty ? 0.0 : masteredCount / all.length,
    };
  }

  // ==================== 초급 전용 (도파민) ====================

  /// 오늘의 단어 (초급용 - 부담 없이)
  Future<VocabularyItem?> getTodayWord() async {
    final reviewWords = await getWordsForReview();
    if (reviewWords.isEmpty) return null;
    
    // 가장 쉬운 거 (정답률 높은 거)
    reviewWords.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    return reviewWords.first;
  }

  /// 격려 메시지 생성
  String getEncouragementMessage(int masteredCount) {
    if (masteredCount == 0) {
      return "첫 단어를 배워볼까요? 🌱";
    } else if (masteredCount < 10) {
      return "벌써 $masteredCount개! 잘하고 있어요 👍";
    } else if (masteredCount < 50) {
      return "$masteredCount개 마스터! 대단해요 🎉";
    } else if (masteredCount < 100) {
      return "와 $masteredCount개! 거의 프로네요 🌟";
    } else {
      return "$masteredCount개 돌파! 언어 천재! 🏆";
    }
  }
}
