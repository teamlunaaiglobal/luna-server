import '../models/learning_level.dart';
import '../models/learning_content.dart';
import '../models/roleplay_scenario.dart';
import '../data/tutor_repository.dart';
import 'progress_tracker.dart';
import 'vocabulary_builder.dart';
import 'grammar_helper.dart';
import 'pronunciation_coach.dart';
import 'culture_guide.dart';
import 'content_analyzer.dart';
import 'roleplay_engine.dart';
import 'realtime_teacher.dart';
import 'conversation_partner.dart';

/// 튜터 서비스 (통합 관리)
/// 모든 튜터 기능을 하나로 묶음
class TutorService {
  /// 싱글톤
  static final TutorService _instance = TutorService._internal();
  factory TutorService() => _instance;
  TutorService._internal();

  // ==================== 서브 서비스들 ====================

  final TutorRepository _repository = TutorRepository();
  final ProgressTracker _progressTracker = ProgressTracker();
  final VocabularyBuilder _vocabularyBuilder = VocabularyBuilder();
  final GrammarHelper _grammarHelper = GrammarHelper();
  final PronunciationCoach _pronunciationCoach = PronunciationCoach();
  final CultureGuide _cultureGuide = CultureGuide();
  final ContentAnalyzer _contentAnalyzer = ContentAnalyzer();
  final RoleplayEngine _roleplayEngine = RoleplayEngine();
  final RealtimeTeacher _realtimeTeacher = RealtimeTeacher();
  final ConversationPartner _conversationPartner = ConversationPartner();

  // ==================== 서브 서비스 접근자 ====================

  ProgressTracker get progress => _progressTracker;
  VocabularyBuilder get vocabulary => _vocabularyBuilder;
  GrammarHelper get grammar => _grammarHelper;
  PronunciationCoach get pronunciation => _pronunciationCoach;
  CultureGuide get culture => _cultureGuide;
  ContentAnalyzer get content => _contentAnalyzer;
  RoleplayEngine get roleplay => _roleplayEngine;
  RealtimeTeacher get realtime => _realtimeTeacher;
  ConversationPartner get conversation => _conversationPartner;

  // ==================== 상태 ====================

  bool _isInitialized = false;
  String? _userId;
  String? _targetLanguage;
  LearningLevel _currentLevel = LearningLevel.beginner;

  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  String? get targetLanguage => _targetLanguage;
  LearningLevel get currentLevel => _currentLevel;

  // ==================== 초기화 ====================

  /// 튜터 서비스 초기화
  Future<void> initialize({
    required String userId,
    required String targetLanguage,
  }) async {
    if (_isInitialized && _userId == userId && _targetLanguage == targetLanguage) {
      return;
    }

    _userId = userId;
    _targetLanguage = targetLanguage;

    // 저장소 초기화
    await _repository.initialize();

    // 진도 추적 초기화
    final progress = await _progressTracker.initialize(userId, targetLanguage);
    _currentLevel = progress.currentLevel;

    // 어휘 빌더 초기화
    _vocabularyBuilder.initialize(userId);

    // 실시간 교재 설정
    _realtimeTeacher.configure(
      targetLanguage: targetLanguage,
      level: _currentLevel,
    );

    _isInitialized = true;
  }

  /// AI 콜백 설정 (문자열 반환)
  void setAICallback(Future<String> Function(String prompt) callback) {
    _cultureGuide.setAICallback(callback);
    _roleplayEngine.setAICallback(callback);
    _conversationPartner.setAICallback(callback);
  }

  /// AI 콜백 설정 (Map 반환)
  void setAICallbackWithMap(Future<Map<String, dynamic>> Function(String prompt) callback) {
    _contentAnalyzer.setAICallback(callback);
  }

  /// AI 콜백 설정 (이미지 분석)
  void setVisionAICallback(
    Future<Map<String, dynamic>> Function(String prompt, String? imagePath) callback,
  ) {
    _realtimeTeacher.setAICallback(callback);
  }

  // ==================== 퀵 액션 ====================

  /// 오늘의 학습 요약
  Map<String, dynamic> getTodaySummary() {
    return _progressTracker.getTodaySummary();
  }

  /// 전체 통계
  Map<String, dynamic> getOverallStats() {
    return _progressTracker.getOverallStats();
  }

  /// 레벨업 준비 됐는지
  bool get isReadyForLevelUp => _progressTracker.isReadyForLevelUp;

  // ==================== 프리토킹 ====================

  /// 프리토킹 시작
  Future<String> startFreeChat({
    ConversationTopic topic = ConversationTopic.freeChat,
  }) async {
    _checkInitialized();

    await _conversationPartner.startConversation(
      targetLanguage: _targetLanguage!,
      level: _currentLevel,
      topic: topic,
    );

    return await _conversationPartner.getGreeting();
  }

  /// 채팅
  Future<String> chat(String message) async {
    return await _conversationPartner.chat(message);
  }

  /// 프리토킹 종료
  Future<Map<String, dynamic>> endChat() async {
    return await _conversationPartner.endConversation();
  }

  // ==================== 롤플레이 ====================

  /// 롤플레이 시작
  Future<String> startRoleplay(RoleplayScenario scenario) async {
    _checkInitialized();

    await _roleplayEngine.startSession(scenario);
    return await _roleplayEngine.getOpeningLine();
  }

  /// 롤플레이 응답
  Future<String> respondInRoleplay(String response) async {
    return await _roleplayEngine.processUserResponse(response);
  }

  /// 롤플레이 종료
  Future<void> endRoleplay() async {
    await _roleplayEngine.endSession();
  }

  // ==================== 실시간 학습 ====================

  /// 카메라로 학습
  Future<List<RecognizedObject>> learnFromCamera(String imagePath) async {
    _checkInitialized();
    return await _realtimeTeacher.recognizeObjects(imagePath);
  }

  /// 텍스트 인식
  Future<List<RecognizedText>> recognizeText(String imagePath) async {
    _checkInitialized();
    return await _realtimeTeacher.recognizeText(imagePath);
  }

  // ==================== 콘텐츠 ====================

  /// 콘텐츠 분석
  Future<ContentAnalysis> analyzeContent({
    required ContentType type,
    required String title,
    required String text,
    required String sourceLanguage,
  }) async {
    _checkInitialized();

    return await _contentAnalyzer.analyze(AnalyzeRequest(
      type: type,
      title: title,
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: _targetLanguage!,
      userLevel: _currentLevel,
    ));
  }

  /// 콘텐츠 저장
  Future<void> saveContent(LearningContent content) async {
    await _repository.saveContent(content);
  }

  /// 레벨별 콘텐츠 조회
  Future<List<LearningContent>> getContentsForCurrentLevel() async {
    _checkInitialized();
    return await _repository.getContentsByLevel(_currentLevel, _targetLanguage!);
  }

  // ==================== 어휘 ====================

  /// 단어 추가
  Future<VocabularyItem> addWord({
    required String word,
    required String meaning,
    String? pronunciation,
    String? example,
  }) async {
    _checkInitialized();

    return await _vocabularyBuilder.addWord(
      word: word,
      meaning: meaning,
      targetLanguage: _targetLanguage!,
      pronunciation: pronunciation,
      exampleSentence: example,
    );
  }

  /// 복습할 단어
  Future<List<VocabularyItem>> getWordsForReview() async {
    return await _vocabularyBuilder.getWordsForReview();
  }

  /// 퀴즈용 단어
  Future<List<VocabularyItem>> getQuizWords({int count = 5}) async {
    return await _vocabularyBuilder.getQuizWords(
      level: _currentLevel,
      count: count,
    );
  }

  /// 단어 정답
  Future<void> markWordCorrect(String word) async {
    await _vocabularyBuilder.recordCorrect(word);
  }

  /// 단어 오답
  Future<void> markWordIncorrect(String word) async {
    await _vocabularyBuilder.recordIncorrect(word);
  }

  /// 단어 통계
  Future<Map<String, dynamic>> getVocabularyStats() async {
    return await _vocabularyBuilder.getStats();
  }

  // ==================== 문화 ====================

  /// 문화 설명
  Future<CultureResponse> explainCulture({
    required String country,
    required String situation,
    CultureCategory? category,
  }) async {
    return await _cultureGuide.explain(CultureRequest(
      country: country,
      situation: situation,
      category: category,
      level: _currentLevel,
    ));
  }

  /// 콘텐츠 문화 맥락
  Future<CultureResponse> explainContentCulture({
    required String content,
    required String country,
    required String scene,
  }) async {
    return await _cultureGuide.explainContent(
      content: content,
      country: country,
      scene: scene,
      level: _currentLevel,
    );
  }

  // ==================== 발음 ====================

  /// 발음 평가
  PronunciationResult evaluatePronunciation({
    required String expected,
    required String recognized,
  }) {
    return _pronunciationCoach.quickEvaluate(
      expectedText: expected,
      recognizedText: recognized,
      level: _currentLevel,
    );
  }

  /// 발음 피드백
  String getPronunciationFeedback(PronunciationResult result) {
    return _pronunciationCoach.generateFeedback(
      result: result,
      level: _currentLevel,
    );
  }

  /// 연습 문장
  List<String> getPracticeSentences() {
    _checkInitialized();
    return _pronunciationCoach.getPracticeSentences(_currentLevel, _targetLanguage!);
  }

  // ==================== 문법 ====================

  /// 문법 피드백
  String getGrammarFeedback(List<GrammarCorrection> corrections) {
    return _grammarHelper.generateFeedback(
      corrections: corrections,
      level: _currentLevel,
    );
  }

  /// 문법 팁
  String getGrammarTip(GrammarCategory category) {
    return _grammarHelper.getGrammarTip(category, _currentLevel);
  }

  // ==================== 초급 전용 ====================

  /// 격려 메시지
  Future<String> getEncouragement() async {
    final stats = await _vocabularyBuilder.getStats();
    final mastered = stats['mastered'] as int? ?? 0;
    return _vocabularyBuilder.getEncouragementMessage(mastered);
  }

  /// 오늘의 단어
  Future<VocabularyItem?> getTodayWord() async {
    return await _vocabularyBuilder.getTodayWord();
  }

  /// 간단 문화 팁
  String getQuickCultureTip(String country) {
    return _cultureGuide.getQuickTip(country, _currentLevel);
  }

  // ==================== 유틸 ====================

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('TutorService not initialized. Call initialize() first.');
    }
  }

  /// 레벨 수동 변경
  void setLevel(LearningLevel level) {
    _currentLevel = level;
    _realtimeTeacher.configure(
      targetLanguage: _targetLanguage ?? 'en',
      level: level,
    );
  }

  /// 초기화 해제
  void dispose() {
    _isInitialized = false;
    _userId = null;
    _targetLanguage = null;
    _currentLevel = LearningLevel.beginner;
  }
}
