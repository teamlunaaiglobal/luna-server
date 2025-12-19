import 'nsa/luna_spinal_cord.dart';
import 'nsa/luna_agent_flash.dart';
import 'nsa/luna_tools.dart';
import 'hardware/luna_tts_service.dart'; // TTS 정지용

class LunaProcessor {
  static final LunaProcessor instance = LunaProcessor._internal();
  factory LunaProcessor() => instance;
  LunaProcessor._internal();

  final LunaAgentFlash _brain = LunaAgentFlash();
  final LunaSpinalCord _spinalCord = LunaSpinalCord();
  bool _isReady = false;

  Future<void> init() async {
    if (!_isReady) {
      await _brain.init();
      _isReady = true;
    }
  }

  /// [핵심] 척수(0원) -> 두뇌(Flash) 순서 처리
  Future<String> processInput(String input) async {
    if (input.trim().isEmpty) return "";

    // 1. 척수 반사 (비용 0원)
    String? reflex = _spinalCord.react(input);
    
    if (reflex != null) {
      if (reflex.startsWith("REFLEX_ACTION:")) {
        String action = reflex.split(":")[1];
        if (action == 'tellTime') return DateTime.now().toString();
        if (action == 'stopAll') {
          await LunaTTSService.instance.stop(); // TTS 정지
          return "모든 작업을 중단했습니다.";
        }
        
        await LunaToolKit.execute(action, {});
        return "실행했습니다!";
      } else {
        return reflex; // 단순 대화 반사
      }
    }

    // 2. 두뇌 판단 (3.0 Flash)
    if (!_isReady) await init();
    try {
      return await _brain.process(input);
    } catch (e) {
      return "죄송해요, 네트워크 연결을 확인해주세요.";
    }
  }
}