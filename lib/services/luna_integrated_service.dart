import '../modules/friend_module.dart';
import '../modules/assist_module.dart';
import '../modules/language_module.dart';
import '../modules/system_module.dart';
import 'luna_unified_block.dart';
import '../models/luna_module_interface.dart'; // LunaMode 사용을 위해 필요

class LunaIntegratedService {
  static final LunaIntegratedService _instance = LunaIntegratedService._internal();
  factory LunaIntegratedService() => _instance;
  LunaIntegratedService._internal();

  final LunaUnifiedBlock _core = LunaUnifiedBlock();

  late final FriendModule friendModule;
  late final AssistModule assistModule;
  late final LunaLanguageModule languageModule;
  late final SystemModule systemModule;

  Future<void> boot() async {
    // -----------------------------
    // 1. 모듈 인스턴스 생성
    // -----------------------------
    friendModule = FriendModule(core: _core);
    assistModule = AssistModule(core: _core);
    languageModule = LunaLanguageModule(core: _core);
    systemModule = SystemModule(core: _core);

    // -----------------------------
    // 2. 모듈 등록
    // -----------------------------
    _core.registerModule(friendModule);
    _core.registerModule(assistModule);
    _core.registerModule(languageModule);
    _core.registerModule(systemModule);

    // -----------------------------
    // 3. 초기 모드 설정
    // -----------------------------
    _core.switchMode(LunaMode.auto); // 자동 모드 시작

    // -----------------------------
    // 4. 모듈 초기화
    // -----------------------------
    await languageModule.init();
    await assistModule.init();
    await friendModule.init();
    await systemModule.init();

    print('🚀 Luna Integrated Service Boot Complete.');
  }

  // -----------------------------
  // 5. 외부 호출용 헬퍼
  // -----------------------------
  Future<String> handleInput(String input) async {
    return await _core.handleInputAuto(input);
  }

  Future<void> stopAll() async {
    await _core.stopAll();
  }

  Future<void> reviewLesson(String topic) async {
    await languageModule.reviewPastLessons(topic);
  }

  Future<String> startLesson(String topic) async {
    return await languageModule.startLesson(topic);
  }
}