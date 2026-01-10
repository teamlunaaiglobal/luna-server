import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class AppLauncherService {
  static final AppLauncherService instance = AppLauncherService._internal();
  factory AppLauncherService() => instance;
  AppLauncherService._internal();

  /// 앱 런처 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('캘린더') || lower.contains('일정 열') || lower.contains('calendar') ||
           lower.contains('알람') || lower.contains('타이머') || lower.contains('timer') ||
           lower.contains('녹음') || lower.contains('record') ||
           lower.contains('카메라') || lower.contains('camera') || lower.contains('사진 찍') ||
           lower.contains('지도') || lower.contains('map') || lower.contains('길 찾') ||
           lower.contains('전화') || lower.contains('call') || lower.contains('통화') ||
           lower.contains('집중 모드') || lower.contains('focus') || lower.contains('방해 금지');
  }

  /// 앱 런처 처리
  Future<String> handle(String input) async {
    final lower = input.toLowerCase();

    if (lower.contains('캘린더') || lower.contains('calendar')) {
      await launchCalendar();
      return "캘린더를 열었어요!";
    }

    if (lower.contains('알람') || lower.contains('타이머') || lower.contains('timer')) {
      await launchTimer();
      return "타이머를 열었어요!";
    }

    if (lower.contains('녹음') || lower.contains('record')) {
      await launchRecorder();
      return "녹음기를 열었어요!";
    }

    if (lower.contains('카메라') || lower.contains('camera') || lower.contains('사진 찍')) {
      await launchCamera();
      return "카메라를 열었어요!";
    }

    if (lower.contains('지도') || lower.contains('map') || lower.contains('길 찾')) {
      await launchMap();
      return "지도를 열었어요!";
    }

    if (lower.contains('전화') || lower.contains('call') || lower.contains('통화')) {
      await launchPhone();
      return "전화 앱을 열었어요!";
    }

    if (lower.contains('집중 모드') || lower.contains('focus') || lower.contains('방해 금지')) {
      await launchFocusMode();
      return "집중 모드를 켰어! 화이팅! 💪";
    }

    return "";
  }

  Future<void> launchCalendar() async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'content://com.android.calendar/time/${DateTime.now().millisecondsSinceEpoch}',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("calshow://");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Calendar launch failed: $e");
    }
  }

  Future<void> launchTimer() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.intent.action.SET_TIMER',
          arguments: <String, dynamic>{'android.intent.extra.alarm.SKIP_UI': false},
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("clock-timer://");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Timer launch failed: $e");
    }
  }

  Future<void> launchRecorder() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.provider.MediaStore.RECORD_SOUND',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint("Recorder launch failed: $e");
    }
  }

  Future<void> launchCamera() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.media.action.IMAGE_CAPTURE',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint("Camera launch failed: $e");
    }
  }

  Future<void> launchMap() async {
    try {
      Uri uri = Platform.isAndroid 
        ? Uri.parse("geo:0,0?q=") 
        : Uri.parse("https://maps.apple.com/?q=");
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("Map launch failed: $e");
    }
  }

  Future<void> launchPhone() async {
    try {
      final uri = Uri(scheme: 'tel', path: '');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (e) {
      debugPrint("Phone launch failed: $e");
    }
  }

  Future<void> launchFocusMode() async {
    try {
      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.settings.ZEN_MODE_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        final uri = Uri.parse("App-prefs:root=DO_NOT_DISTURB");
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Focus mode launch failed: $e");
    }
  }
}
