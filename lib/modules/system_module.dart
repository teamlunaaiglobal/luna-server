import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/luna_processor.dart';
import '../core/interfaces/luna_module_interface.dart';

class SystemModule extends LunaModule {
  final LunaProcessor core;

  int _dailyUsed = 0;
  int _currentMaxLimit = 30; 
  String _lastAccessDate = "";

  SystemModule({required this.core});

  @override
  String get id => "system";

  @override
  List<LunaMode> get supportedModes => LunaMode.values; 

  String get moduleName => "SystemModule";

  @override
  Future<void> initialize() async {
    await _init();
  }

  @override
  Future<String?> execute(String input) async {
    await increaseUsage(); 
    if (input == "/reset_usage") {
      await _resetAll();
      return "시스템 리셋 완료 (Limit 30)";
    }
    return null;
  }

  @override
  Future<void> handleFailure(dynamic error) async {
    if (kDebugMode) debugPrint("⚠️ SystemModule Error: $error");
  }

  // =================================================================
  // 👉 [여기가 핵심] 아까 빠져있던 한 줄을 추가했습니다!
  // =================================================================

  int get dailyUsed => _dailyUsed;

  // 👇 [이 줄이 없어서 에러가 났던 겁니다! 이제 추가됨]
  int get currentMaxLimit => _currentMaxLimit;

  int get currentLevel => _currentMaxLimit;
  double get currentExp {
    if (_currentMaxLimit == 0) return 0.0;
    return _dailyUsed / _currentMaxLimit;
  }

  // =================================================================

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyUsed = prefs.getInt('luna_daily_used') ?? 0;
    _currentMaxLimit = prefs.getInt('luna_max_limit') ?? 30;
    _lastAccessDate = prefs.getString('luna_last_date') ?? "";

    await _checkDateAndReset(prefs);

    if (kDebugMode) {
      debugPrint("🛠 SystemModule Loaded. Used: $_dailyUsed / Limit: $_currentMaxLimit");
    }
  }

  Future<void> increaseUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDateAndReset(prefs);

    if (_dailyUsed < _currentMaxLimit) {
      _dailyUsed++;
      await prefs.setInt('luna_daily_used', _dailyUsed);
    }
  }

  Future<void> _checkDateAndReset(SharedPreferences prefs) async {
    String today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastAccessDate != today) {
      await _resetAll();
      _lastAccessDate = today;
      await prefs.setString('luna_last_date', today);
    }
  }

  Future<void> _resetAll() async {
    _dailyUsed = 0;
    _currentMaxLimit = 30;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('luna_daily_used', 0);
    await prefs.setInt('luna_max_limit', 30);
  }

  Future<void> applyRefillReward() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyUsed = 0;
    if (_currentMaxLimit <= 24) {
      _currentMaxLimit = 30;
    } else {
      _currentMaxLimit = _currentMaxLimit - 1;
    }
    await prefs.setInt('luna_daily_used', _dailyUsed);
    await prefs.setInt('luna_max_limit', _currentMaxLimit);
  }
}