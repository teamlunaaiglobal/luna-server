import 'package:flutter/foundation.dart';
import '../models/luna_module_interface.dart';

// [설명] AI OS의 핵심 커널 (싱글톤 패턴)
class LunaKernelService {
  static final LunaKernelService _instance = LunaKernelService._internal();
  factory LunaKernelService() => _instance;
  LunaKernelService._internal();

  // 현재 활성화된 모드 (기본: Friend)
  LunaMode _currentMode = LunaMode.friend;
  
  // 등록된 모듈 저장소 (예: 일정 모듈, 채팅 모듈 등)
  final Map<String, LunaModule> _modules = {};

  // 상태 조회
  LunaMode get currentMode => _currentMode;

  // [기능 1] 모드 전환
  void switchMode(LunaMode newMode) {
    _currentMode = newMode;
    debugPrint('🔄 Luna OS Mode Switched: ${newMode.name.toUpperCase()}');
  }

  // [기능 2] 기능 모듈 장착 (확장성)
  void registerModule(LunaModule module) {
    _modules[module.id] = module;
    module.initialize().then((_) {
      debugPrint('✅ Module Loaded: ${module.id}');
    }).catchError((e) {
      debugPrint('❌ Module Load Failed: ${module.id} / Error: $e');
    });
  }

  // [기능 3] 명령 처리 및 배분 (Routing)
  Future<void> processCommand(String command) async {
    debugPrint('🧠 Kernel Processing: "$command" in [${_currentMode.name}] mode');
    
    // TODO: 강화학습 모델이 붙으면 여기서 어떤 모듈을 쓸지 자동으로 결정함
    // 현재는 등록된 모든 모듈을 순회하며 호환되는지 확인 (임시 로직)
    
    bool handled = false;
    for (var module in _modules.values) {
      if (module.supportedModes.contains(_currentMode)) {
        try {
          await module.execute(command);
          handled = true;
        } catch (e) {
          await module.handleFailure(e.toString());
        }
      }
    }

    if (!handled) {
      debugPrint('⚠️ No module handled this command.');
    }
  }
}