// lib/services/luna_boot_service.dart
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class LunaBootService {
  static final LunaBootService _instance = LunaBootService._internal();
  factory LunaBootService() => _instance;
  LunaBootService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint("🚀 Luna System Booting...");
    
    // 1. 필수 저장소 로드
    await SharedPreferences.getInstance();
    
    // 2. (필요 시) 추가적인 초기화 로직
    
    _isInitialized = true;
    debugPrint("✅ Luna System Ready.");
  }
}