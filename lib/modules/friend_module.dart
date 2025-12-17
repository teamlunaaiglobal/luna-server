import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/luna_module_interface.dart';
import '../services/luna_unified_block.dart'; // [필수] Core 연결

class FriendModule implements LunaModule {
  final LunaUnifiedBlock core; // [필수] Core 주입 변수

  // [수정] 생성자에서 core를 받도록 변경
  FriendModule({required this.core});

  final bool _isSimulationMode = true; 
  final String _apiKey = "INSERT_YOUR_KEY_HERE"; 

  @override
  String get id => 'friend_core';

  @override
  List<LunaMode> get supportedModes => [LunaMode.friend, LunaMode.auto];

  // [매핑] IntegratedService가 호출하는 init() -> initialize() 연결
  Future<void> init() async => await initialize();

  @override
  Future<void> initialize() async {
    debugPrint('💖 Friend Module Ready (Connected to Core).');
  }

  @override
  Future<dynamic> execute(String command) async {
    if (_isSimulationMode) return _runSimulation(command);
    return await _runRealFriend(command);
  }

  String _runSimulation(String input) {
    if (input.contains("안녕")) return "오빠 왔어? 보고 싶었어! 💕";
    return "응, 듣고 있어. ($input)";
  }

  Future<String> _runRealFriend(String input) async {
    if (_apiKey.contains("INSERT")) return "Error: Key Missing";
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [{'role': 'system', 'content': 'You are a lovely girlfriend.'}, {'role': 'user', 'content': input}],
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
      }
      return "Error: ${response.statusCode}";
    } catch (e) {
      return "Network Error: $e";
    }
  }

  @override
  Future<void> handleFailure(String error) async {}
}