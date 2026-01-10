import '../services/search/duckduckgo_service.dart';
import '../services/nsa/luna_spinal_cord.dart';
import '../services/emotion_engine.dart';
import '../services/nsa/luna_tools.dart';
import '../services/hardware/luna_tts_service.dart' hide EmotionTag;
import '../services/memory/conversation_memory.dart';
import '../modules/teacher/services/teacher_ai_service.dart';
import '../util/action_handler.dart';
import '../services/proactive/proactive_engine.dart';

class LunaProcessor {
  static final LunaProcessor instance = LunaProcessor._internal();
  factory LunaProcessor() => instance;
  LunaProcessor._internal();

  final LunaSpinalCord _spinalCord = LunaSpinalCord();
  final LunaBrain _brain = LunaBrain();
  final ConversationMemory _memory = ConversationMemory();
  final TeacherAIService _tutor = TeacherAIService.instance;
  final DuckDuckGoService _search = DuckDuckGoService();
  String _currentMode = 'friend'; // friend, tutor, secretary, search
  final ProactiveEngine _proactive = ProactiveEngine.instance;

  bool _isReady = false;

  Future<void> init() async {
    await _proactive.init();
    _isReady = true;
  }

  /// [모드 감지] 입력 내용 보고 모드 판단
  String _detectMode(String input) {
    final lower = input.toLowerCase();

    // Search 모드 키워드
    if (lower.contains('검색') ||
        lower.contains('찾아') ||
        lower.contains('알려줘') ||
        lower.contains('뭐야') ||
        lower.contains('search') ||
        lower.contains('what is') ||
        lower.contains('who is') ||
        lower.contains('날씨') ||
        lower.contains('weather')) {
      return 'search';
    }

    // Tutor 모드 키워드 (글로벌 - 다국어 지원)
    if (lower.contains('공부') ||
        lower.contains('학습') ||
        lower.contains('뭐라고 해') ||
        lower.contains('어떻게 말해') ||
        lower.contains('번역') ||
        lower.contains('language') ||
        lower.contains('study') ||
        lower.contains('learn') ||
        lower.contains('translate') ||
        lower.contains('how do you say') ||
        lower.contains('勉強') ||
        lower.contains('学习')) {
      return 'tutor';
    }

    // Secretary 모드 키워드
    if (lower.contains('일정') ||
        lower.contains('회의') ||
        lower.contains('알람') ||
        lower.contains('리마인드') ||
        lower.contains('예약') ||
        lower.contains('메모')) {
      return 'secretary';
    }

    // 기본은 Friend 모드
    return 'friend';
  }

  Future<String> processInput(String input) async {
    if (input.trim().isEmpty) return "";

    // 1. 척수 반사 (비용 0원)
    String? reflex = _spinalCord.react(input);
    
    if (reflex != null) {
      if (reflex.startsWith("REFLEX_ACTION:")) {
        String action = reflex.split(":")[1];
        if (action == 'tellTime') return DateTime.now().toString();
        if (action == 'stopAll') {
          await LunaTTSService.instance.stop();
          return "모든 작업을 중단했습니다.";
        }
        await LunaToolKit.execute(action, {});
        return "실행했습니다!";
      } else {
        return reflex;
      }
    }

    // 2. 모드 감지
    if (!_isReady) await init();
    _currentMode = _detectMode(input);
    
    String response;
    
    try {
      // 3. 모드별 처리
      switch (_currentMode) {
        case 'search':
          response = await _search.search(input);
          break;
        case 'tutor':
          final material = await _tutor.fetchMaterial(type: 'conversation');
          response = "📚 학습 모드: ${material.title}\n${material.contentOriginal}";
          break;
        case 'secretary':
          String actionResult = await ActionHandler.executeAction(input);
          if (actionResult == "EMAIL_DRAFT_MODE") {
            response = await _brain.getResponse("다음 내용으로 정중한 비즈니스 이메일 초안을 한국어로 작성해줘: $input");
          } else if (actionResult.isNotEmpty) {
            response = actionResult;
          } else {
            response = await _brain.getResponse(input);
          }
          break;
        case 'friend':
        default:
          response = await _brain.getResponse(input);
          break;
      }
    } catch (e) {
      // 폴백: Flash 직통
      try {
        response = "죄송해요, 다시 시도해주세요.";
      } catch (e2) {
        response = "죄송해요, 네트워크 연결을 확인해주세요.";
      }    }

    // 4. 대화 저장
    await _saveConversation(input, response);

    // 5. 능동적 제안 체크
    final suggestion = _proactive.analyze(input);
    if (suggestion != null) {
      response = "$response\n\n---\n💡 ${suggestion.message}";
    }
    
    return response;
  }


  Future<void> _saveConversation(String input, String response) async {
    await _memory.saveMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: input,
      emotion: 'neutral',
      timestamp: DateTime.now(),
    ));
    await _memory.saveMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'luna',
      text: response,
      emotion: 'neutral',
      timestamp: DateTime.now(),
    ));
  }
}
