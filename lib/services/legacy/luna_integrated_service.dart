import 'dart:async';
import 'package:flutter/foundation.dart';

// [Imports]
import '../../core/luna_processor.dart';
import '../../modules/system_module.dart';
import 'luna_unified_block.dart';

class LunaIntegratedService {
  // [삭제됨] final LunaUnifiedBlock _legacyCore;  <-- 안 쓰니까 삭제!
  
  late final SystemModule _system;

  // 생성자: 밖에서 옛날 두뇌를 던져주긴 하지만, 우리는 받아서 무시합니다 (호환성 유지용)
  LunaIntegratedService(LunaUnifiedBlock ignoredCore) {
    // 우리는 신형(LunaProcessor)으로 갈아탑니다.
    _system = SystemModule(core: LunaProcessor.instance); 
  }

  Future<void> initialize() async {
    await _system.initialize();
    
    if (kDebugMode) {
      debugPrint("Legacy Service: Bridged to SystemModule successfully.");
    }
  }

  SystemModule get system => _system;
}