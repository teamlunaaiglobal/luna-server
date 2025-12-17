import 'dart:async';
import 'package:flutter/foundation.dart';
import 'luna_boot_service.dart'; // [유지] 대표님 방식대로 부트 서비스 직접 호출
import '../models/luna_module_interface.dart';

class LunaUnifiedBlock {
  // 싱글톤 패턴 (유지)
  static final LunaUnifiedBlock _instance = LunaUnifiedBlock._internal();
  factory LunaUnifiedBlock() => _instance;
  LunaUnifiedBlock._internal();

  // 기본 모드
  LunaMode _currentMode = LunaMode.friend;

  // ---------------------------------------------------------------------------
  // [핵심] 채팅창에서 호출하는 함수
  // ---------------------------------------------------------------------------
  Future<String> handleInputAuto(String input) async {
    if (input.trim().isEmpty) return "";

    // 1. [스마트 감지] 명령어(/) 대신, 말의 내용으로 모드를 바꿈
    _checkModeSwitchIntent(input);

    // 2. [학습 명령어 감지]
    if (input.startsWith("lesson:") || input.startsWith("answer:")) {
      return await LunaBootService.languageModule.execute(input);
    }

    // 3. 모듈 실행 (대표님 코드 방식 그대로 유지)
    try {
      switch (_currentMode) {
        case LunaMode.assist:
          return await LunaBootService.assistModule.execute(input);

        case LunaMode.tutor:
          // 튜터 모드일 때는 일반 대화도 학습 모듈로
          if (input.contains("수업") || input.contains("시작")) {
            return await LunaBootService.languageModule.execute("lesson:general");
          }
          return await LunaBootService.languageModule.execute("conversation:$input");

        case LunaMode.system:
          // 시스템은 한번 실행 후 친구로 복귀
          String result = await LunaBootService.systemModule.execute(input);
          _currentMode = LunaMode.friend; 
          return result;

        case LunaMode.friend:
        default:
          return await LunaBootService.friendModule.execute(input);
      }
    } catch (e) {
      debugPrint("Error in UnifiedBlock: $e");
      return "오류가 났어 오빠. 다시 말해줄래? ($e)";
    }
  }

  // ---------------------------------------------------------------------------
  // [눈치 로직] 대표님이 원하신 "대화로 모드 전환" 기능
  // ---------------------------------------------------------------------------
  void _checkModeSwitchIntent(String input) {
    String text = input.replaceAll(" ", ""); // 띄어쓰기 무시

    // 비서 모드 감지
    if (text.contains("비서모드") || text.contains("업무") || text.contains("일정") || text.contains("스케줄")) {
      _currentMode = LunaMode.assist;
      debugPrint("Mode Switched to Assist");
    }
    // 학습 모드 감지
    else if (text.contains("공부") || text.contains("학습") || text.contains("영어") || text.contains("수업")) {
      _currentMode = LunaMode.tutor;
      debugPrint("Mode Switched to Tutor");
    }
    // 친구 모드 감지
    else if (text.contains("친구") || text.contains("놀자") || text.contains("안녕")) {
      _currentMode = LunaMode.friend;
      debugPrint("Mode Switched to Friend");
    }
    // 시스템 감지
    else if (text.contains("배터리") || text.contains("시스템")) {
      _currentMode = LunaMode.system;
    }
  }
}