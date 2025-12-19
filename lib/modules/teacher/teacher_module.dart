// [추가] debugPrint를 사용하기 위해 import
import 'package:flutter/foundation.dart';
import 'ui/teacher_screen.dart';
import 'services/teacher_ai_service.dart';

class TeacherModule {
  // 모듈 정보
  String get moduleName => "Teacher Mode";
  String get moduleId => "teacher";

  // 초기화 로직
  Future<void> initialize() async {
    // [수정] print -> debugPrint
    debugPrint("Teacher Module Loading...");
    await TeacherAIService.instance.initialize();
  }

  // 메인 화면 반환
  dynamic getMainScreen() {
    return const TeacherScreen();
  }
}