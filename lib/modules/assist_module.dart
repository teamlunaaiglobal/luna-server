import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/interfaces/luna_module_interface.dart';
import '../services/luna_unified_block.dart'; // [필수]

class AssistModule implements LunaModule {
  final LunaUnifiedBlock core; // [필수]
  AssistModule({required this.core}); // [필수] 생성자 수정

  final bool _isSimulationMode = true;
  final String _apiKey = "INSERT_YOUR_KEY_HERE";

  @override
  String get id => 'assist_core';

  @override
  List<LunaMode> get supportedModes => [LunaMode.assist, LunaMode.auto];

  Future<void> init() async => await initialize(); // [매핑]

  @override
  Future<void> initialize() async {
    debugPrint('💼 Assist Module Initialized (Connected to Core).');
  }

  @override
  Future<dynamic> execute(String command) async {
    if (_isSimulationMode) return _runSimulation(command);
    return await _runRealAgent(command);
  }

  String _runSimulation(String command) {
    if (command.contains("일정")) return "내일 오전 10시 미팅이 있습니다.";
    return "요청하신 업무($command)를 확인했습니다.";
  }

  Future<String> _runRealAgent(String command) async {
    if (_apiKey.contains("INSERT")) return "Error: Key Missing";
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [{'role': 'system', 'content': 'You are a professional secretary.'}, {'role': 'user', 'content': command}],
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
      }
      return "Server Error: ${response.statusCode}";
    } catch (e) {
      return "Network Error: $e";
    }
  }

  @override
  Future<void> handleFailure(String error) async {}
}