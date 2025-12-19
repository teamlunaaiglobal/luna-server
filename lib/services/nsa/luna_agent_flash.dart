import 'package:google_generative_ai/google_generative_ai.dart';
import 'luna_tools.dart';

class LunaAgentFlash {
  static const String _apiKey = "YOUR_GEMINI_API_KEY"; // 키 입력 필수
  late final GenerativeModel _model;
  late final ChatSession _chat;

  Future<void> init() async {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp', // 최신 Flash 모델
      apiKey: _apiKey,
      tools: LunaToolKit.tools,
      systemInstruction: Content.system("You are Luna, a helpful AI friend. Be concise."),
    );
    _chat = _model.startChat();
  }

  Future<String> process(String input) async {
    var response = await _chat.sendMessage(Content.text(input));
    
    // AI가 도구 사용을 요청했는지 확인
    final functionCalls = response.functionCalls;
    if (functionCalls.isNotEmpty) {
      for (var call in functionCalls) {
        final result = await LunaToolKit.execute(call.name, call.args);
        response = await _chat.sendMessage(Content.functionResponse(call.name, result));
      }
    }
    return response.text ?? "";
  }
}