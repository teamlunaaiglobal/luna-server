import 'package:flutter/foundation.dart'; // [추가] debugPrint 사용
import 'package:google_generative_ai/google_generative_ai.dart';
import '../hardware/luna_vision_service.dart';
import '../hardware/luna_hearing_service.dart';

class LunaToolKit {
  // 3.0 Flash에게 쥐여줄 도구 설명서
  static final List<Tool> tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'openCamera',
        'Use when user wants to SHOW something.',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'turnOnMic',
        'Use when user wants to SPEAK.',
        Schema(SchemaType.object, properties: {}),
      ),
    ]),
  ];

  // 실제 실행기
  static Future<Map<String, Object?>> execute(String name, Map<String, Object?> args) async {
    // [수정] print -> debugPrint
    debugPrint("🛠️ Tool Executing: $name");
    
    switch (name) {
      case 'openCamera':
        var file = await LunaVisionService.instance.captureOptimization();
        return {'result': file != null ? 'Image captured' : 'Cancelled'};
      case 'turnOnMic':
        LunaHearingService.instance.startListening();
        return {'result': 'Mic started'};
      default:
        return {'error': 'Unknown tool'};
    }
  }
}