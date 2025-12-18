import 'package:flutter/foundation.dart'; // [Fix] debugPrint 사용을 위해 추가
import 'package:shared_preferences/shared_preferences.dart';
import '../services/luna_unified_block.dart';
import '../models/luna_module_interface.dart';

class SystemModule extends LunaModule {
  final LunaUnifiedBlock core;
  
  // 내부 변수
  int _dailyUsed = 0;
  int _currentMaxLimit = 30; // [비밀] 가변 배터리 용량
  String _lastAccessDate = "";

  SystemModule({required this.core});

  // -----------------------------------------------------------------
  // [Fix 1] 부모 클래스(LunaModule)가 요구하는 필수 오버라이드 구현
  // -----------------------------------------------------------------
  
  @override
  String get id => "system"; // id는 부모에 존재하므로 유지

  // moduleName은 부모에 없으므로 @override 제거
  String get moduleName => "SystemModule"; 

  @override
  List<LunaMode> get supportedModes => LunaMode.values; // 부모에 존재하므로 유지

  // 외부 공개 Getter
  int get dailyUsed => _dailyUsed;
  int get currentMaxLimit => _currentMaxLimit;

  // -----------------------------------------------------------------
  // [Fix 2] init -> initialize (이름 변경)
  // -----------------------------------------------------------------
  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyUsed = prefs.getInt('luna_daily_used') ?? 0;
    _currentMaxLimit = prefs.getInt('luna_max_limit') ?? 30; 
    _lastAccessDate = prefs.getString('luna_last_date') ?? "";

    await _checkDateAndReset(prefs);
    
    // [Fix] print -> debugPrint (경고 해결)
    if (kDebugMode) {
      debugPrint("🛠 SystemModule Initialized. Used: $_dailyUsed / Limit: $_currentMaxLimit");
    }
  }

  // -----------------------------------------------------------------
  // [Fix 3] processInput -> execute (이름 변경)
  // -----------------------------------------------------------------
  @override
  Future<String?> execute(String input) async {
    // [Critical] 모든 입력에 대해 사용량 증가
    await increaseUsage();

    // 시스템 명령어 처리
    if (input == "/reset_usage") {
      final prefs = await SharedPreferences.getInstance();
      
      // 테스트용 강제 리셋
      _dailyUsed = 0;
      _currentMaxLimit = 30;
      
      await prefs.setInt('luna_daily_used', 0);
      await prefs.setInt('luna_max_limit', 30);
      return "[System] 사용량 및 배터리 효율이 초기화되었습니다 (30).";
    }
    
    return null; 
  }

  // -----------------------------------------------------------------
  // [Fix 4] handleFailure 추가 (필수 구현 누락 해결)
  // -----------------------------------------------------------------
  @override
  Future<void> handleFailure(dynamic error) async {
    if (kDebugMode) {
      debugPrint("⚠️ SystemModule Error: $error");
    }
  }

  // -----------------------------------------------------------------
  // 내부 로직 (스텔스 BM & 유틸리티) - 기존 로직 유지
  // -----------------------------------------------------------------

  Future<void> _checkDateAndReset(SharedPreferences prefs) async {
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (_lastAccessDate != today) {
      _dailyUsed = 0;
      _currentMaxLimit = 30; 
      _lastAccessDate = today;
      
      await prefs.setInt('luna_daily_used', 0);
      await prefs.setInt('luna_max_limit', 30);
      await prefs.setString('luna_last_date', today);
      if (kDebugMode) debugPrint("📅 New Day Detected. Full Reset (Limit 30).");
    }
  }

  Future<void> increaseUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDateAndReset(prefs);

    _dailyUsed++;
    await prefs.setInt('luna_daily_used', _dailyUsed);
  }

  /// [비밀 사이클] 광고 시청 후 호출
  Future<void> applyRefillReward() async {
    final prefs = await SharedPreferences.getInstance();
    
    _dailyUsed = 0; // 게이지 초기화
    
    // 감가 로직 (30 -> 29 ... -> 24 -> 30)
    if (_currentMaxLimit <= 24) {
      _currentMaxLimit = 30;
      if (kDebugMode) debugPrint("🎁 Jackpot! Battery Restored to 30.");
    } else {
      _currentMaxLimit = _currentMaxLimit - 1;
      if (kDebugMode) debugPrint("⚡ Stealth Degradation. Next Capacity: $_currentMaxLimit");
    }
    
    await prefs.setInt('luna_daily_used', _dailyUsed);
    await prefs.setInt('luna_max_limit', _currentMaxLimit);
  }
}