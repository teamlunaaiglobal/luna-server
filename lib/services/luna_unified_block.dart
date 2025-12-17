import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/luna_module_interface.dart';

class LunaUnifiedBlock {
  // 싱글톤 패턴 유지
  static final LunaUnifiedBlock _instance = LunaUnifiedBlock._internal();
  factory LunaUnifiedBlock() => _instance;
  LunaUnifiedBlock._internal();

  // [신규] 모듈 레지스트리 (IntegratedService에서 등록된 모듈들)
  final List<LunaModule> _modules = [];

  // [기본 상태] 평소에는 친구(Friend)로 대기
  LunaMode _currentMode = LunaMode.friend;

  // ---------------------------------------------------------------------------
  // [신규] 시스템 연동을 위한 필수 메서드 (IntegratedService용)
  // ---------------------------------------------------------------------------
  void registerModule(LunaModule module) {
    _modules.add(module);
    debugPrint("🧩 Module Registered in Brain: ${module.id}");
  }

  void switchMode(LunaMode mode) {
    _currentMode = mode;
    debugPrint("🔄 Mode Force Switched to: $mode");
  }

  Future<void> stopAll() async {
    _currentMode = LunaMode.system;
    debugPrint("🛑 Brain Stopped.");
  }

  // ---------------------------------------------------------------------------
  // [메인] 눈치껏 알아서 처리하는 함수 (대표님 로직 + 동적 모듈 실행)
  // ---------------------------------------------------------------------------
  Future<String> handleInputAuto(String input) async {
    if (input.trim().isEmpty) return "";

    // 1. [눈치 보기] 대표님의 '강력한 신호 감지' 로직 그대로 적용
    LunaMode? detectedIntent = _detectStrongSignal(input);

    // 2. [태세 전환] 신호 감지 시 모드 변경
    if (detectedIntent != null) {
      _currentMode = detectedIntent;
      // 튜터 모드 감지 시, 수업 시작 신호면 내부적으로 처리
      if (_currentMode == LunaMode.tutor && (input.contains("수업") || input.contains("시작"))) {
        return await _executeModule(LunaMode.tutor, "lesson:general");
      }
    }

    // 3. [실행] 결정된 모드로 모듈 찾아서 실행 (동적 바인딩)
    // 기존의 static 호출(LunaBootService...) 대신 등록된 모듈을 사용
    return await _executeModule(_currentMode, input);
  }

  // ---------------------------------------------------------------------------
  // [보조] 모듈 실행기 (구조적 업그레이드)
  // ---------------------------------------------------------------------------
  Future<String> _executeModule(LunaMode mode, String command) async {
    try {
      // 현재 모드를 지원하는 모듈을 리스트에서 찾음
      LunaModule target = _modules.firstWhere(
        (m) => m.supportedModes.contains(mode),
        orElse: () => _modules.firstWhere((m) => m.supportedModes.contains(LunaMode.friend))
      );
      
      return await target.execute(command);
    } catch (e) {
      debugPrint("Module Execution Error: $e");
      return "오류가 발생했습니다: $e";
    }
  }

  // ---------------------------------------------------------------------------
  // [판단 로직] 대표님 작성 코드 원본 유지 (Logic Preservation)
  // ---------------------------------------------------------------------------
  LunaMode? _detectStrongSignal(String input) {
    String text = input.replaceAll(" ", ""); 

    // 1. [비서/업무 신호]
    if (text.contains("일정") || text.contains("스케줄") || text.contains("메일") || 
        text.contains("브리핑") || text.contains("보고") || text.contains("결재") ||
        text.contains("회의") || text.contains("미팅")) {
      return LunaMode.assist;
    }

    // 2. [학습/외국어 신호]
    if (text.contains("영어") || text.contains("중국어") || text.contains("공부") || 
        text.contains("학습") || text.contains("해석") || text.contains("뜻이야?")) {
      return LunaMode.tutor;
    }

    // 3. [시스템/제어 신호]
    if (text.contains("배터리") || text.contains("와이파이") || text.contains("볼륨") || text.contains("시스템")) {
      return LunaMode.system;
    }

    // 4. [감성/친구 신호]
    if (text.contains("안녕") || text.contains("힘들다") || text.contains("사랑") || 
        text.contains("배고파") || text.contains("놀자") || text.contains("심심")) {
      return LunaMode.friend;
    }

    return null; 
  }
}