import 'dart:math';
import 'package:flutter/foundation.dart';

enum AIProvider {
  onDevice,  // 폰 내장 AI (Gemini Nano / Core ML)
  server,    // 서버 AI (Qwen)
  cloud,     // 클라우드 API (Gemini Cloud) - 백업용
}

class AIManager {
  static final AIManager instance = AIManager._internal();
  factory AIManager() => instance;
  AIManager._internal();

  // 추임새 리스트 (즉시 반응용)
  static const List<String> fillerResponses = [
    "음...",
    "잠깐만...",
    "생각해볼게...",
    "어디보자...",
    "흠...",
    "잠시만요~",
    "그게...",
  ];

  // 랜덤 추임새 반환
  static String getFillerResponse() {
    final random = Random();
    return fillerResponses[random.nextInt(fillerResponses.length)];
  }

  AIProvider _currentProvider = AIProvider.cloud;
  bool _isOnDeviceAvailable = false;
  bool _isInitialized = false;

  AIProvider get currentProvider => _currentProvider;
  bool get isOnDeviceAvailable => _isOnDeviceAvailable;

  Future<void> init() async {
    if (_isInitialized) return;

    // 내장 AI 지원 여부 체크
    _isOnDeviceAvailable = await _checkOnDeviceAI();

    // 자동 선택
    if (_isOnDeviceAvailable) {
      _currentProvider = AIProvider.onDevice;
      debugPrint("🤖 AI Manager: 폰 내장 AI 사용");
    } else {
      _currentProvider = AIProvider.cloud;
      debugPrint("☁️ AI Manager: 클라우드 API 사용 (내장 AI 미지원)");
    }

    _isInitialized = true;
  }

  Future<bool> _checkOnDeviceAI() async {
    // TODO: 실제 내장 AI 지원 체크 로직
    // Android: Gemini Nano 지원 여부
    // iOS: Core ML 지원 여부
    // 지금은 false 반환 (나중에 구현)
    return false;
  }

  Future<String> generateResponse(String input, String context) async {
    switch (_currentProvider) {
      case AIProvider.onDevice:
        return await _callOnDeviceAI(input, context);
      case AIProvider.server:
        return await _callServerAI(input, context);
      case AIProvider.cloud:
        return await _callCloudAI(input, context);
    }
  }

  Future<String> _callOnDeviceAI(String input, String context) async {
    // TODO: Gemini Nano / Core ML 호출
    // 지금은 placeholder
    return "내장 AI 응답 (구현 예정)";
  }

  Future<String> _callServerAI(String input, String context) async {
    // TODO: 서버 Qwen 호출
    // 지금은 placeholder
    return "서버 AI 응답 (구현 예정)";
  }

  Future<String> _callCloudAI(String input, String context) async {
    // 기존 Gemini Cloud API 호출
    // LunaBrain에서 가져올 예정
    return "클라우드 AI 응답";
  }

  // 수동으로 provider 변경 (테스트용)
  void setProvider(AIProvider provider) {
    _currentProvider = provider;
    debugPrint("🔄 AI Provider 변경: $provider");
  }
}
