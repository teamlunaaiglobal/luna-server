import 'package:flutter/foundation.dart';
import '../models/luna_module_interface.dart';
import '../services/luna_unified_block.dart'; // [필수]

class SystemModule implements LunaModule {
  final LunaUnifiedBlock core; // [필수]
  SystemModule({required this.core}); // [필수] 생성자 수정

  final bool _isSimulationMode = true;

  @override
  String get id => 'system_core';

  @override
  List<LunaMode> get supportedModes => LunaMode.values;

  Future<void> init() async => await initialize(); // [매핑]

  @override
  Future<void> initialize() async {
    debugPrint('⚙️ System Module Green (Connected to Core).');
  }

  @override
  Future<dynamic> execute(String command) async {
    if (_isSimulationMode) return _runSimulation(command);
    return await _runRealSystem(command);
  }

  String? _runSimulation(String command) {
    if (command.contains("status_check")) return "System OK";
    if (command.contains("배터리")) return "현재 배터리 85%입니다.";
    if (command.contains("와이파이") || command.contains("네트워크")) return "Wi-Fi 신호 강함.";
    if (command.contains("볼륨")) return "현재 볼륨 50%입니다.";
    return "시스템 대기 중";
  }

  Future<dynamic> _runRealSystem(String command) async {
    return null;
  }

  @override
  Future<void> handleFailure(String error) async {
    debugPrint('⚠️ System Error: $error');
  }
}