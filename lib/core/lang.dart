import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class Lang {
  static String _language = 'en'; // 기본값
  static bool _isLoaded = false;

  // [초기화]
  static Future<void> init() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('user_language');

    if (savedLang != null) {
      _language = savedLang;
    } else {
      String systemLocale = PlatformDispatcher.instance.locale.languageCode;
      if (['ko', 'zh', 'en'].contains(systemLocale)) {
        _language = systemLocale;
      } else {
        _language = 'en';
      }
      await prefs.setString('user_language', _language);
    }
    _isLoaded = true;
  }

  // 🗣️ 입을 위한 코드 (TTS: ko-KR)
  static String get ttsCode {
    switch (_language) {
      case 'ko': return 'ko-KR';
      case 'zh': return 'zh-CN';
      case 'en': 
      default: return 'en-US';
    }
  }

  // 👂 귀를 위한 코드 (STT: ko_KR) ★ [NEW] 언더바(_) 필수
  static String get sttCode {
    switch (_language) {
      case 'ko': return 'ko_KR';
      case 'zh': return 'zh_CN';
      case 'en': 
      default: return 'en_US';
    }
  }

  // [언어 데이터베이스]
  static final Map<String, Map<String, String>> _db = {
    // 시스템
    'system_online': {'en': 'System Online. I am LUNA.', 'ko': '시스템 가동. 저는 루나입니다.', 'zh': '系统在线。我是Luna。'},
    'mic_denied': {'en': 'Microphone permission denied.', 'ko': '마이크 권한이 없습니다.', 'zh': '麦克风权限被拒绝。'},
    'image_uploaded': {'en': '[Image Uploaded]', 'ko': '[사진이 업로드되었습니다]', 'zh': '[图片已上传]'},
    'hint': {'en': 'Type a message...', 'ko': '대화를 입력하세요...', 'zh': '输入消息...'},
    
    // 모드
    'mode_assistant': {'en': 'Assistant', 'ko': '비서 모드', 'zh': '助理模式'},
    'mode_learning': {'en': 'Learning', 'ko': '학습 모드', 'zh': '学习模式'},
    'mode_friends': {'en': 'Friends', 'ko': '친구 모드', 'zh': '朋友模式'},

    // 상태
    'luna': {'en': 'LUNA', 'ko': '루나', 'zh': 'LUNA'},
    'rec': {'en': 'REC', 'ko': '듣고 있어요', 'zh': '聆听中'},

    // 대시보드
    'my_companion': {'en': 'MY COMPANION', 'ko': '나의 동반자', 'zh': '我的伙伴'},
    'together': {'en': 'TOGETHER', 'ko': '함께하기', 'zh': '在一起'},
    'deep_talk': {'en': 'Deep Talk', 'ko': '깊은 대화', 'zh': '深度交谈'},
    'emotion': {'en': 'Emotion Check', 'ko': '기분 어때?', 'zh': '心情检查'},
    
    'progress': {'en': 'PROGRESS', 'ko': '나의 성장', 'zh': '我的成长'},
    'daily_goal': {'en': 'Daily Goal', 'ko': '오늘의 목표', 'zh': '今日目标'},
    'review': {'en': 'Review', 'ko': '기억 되살리기', 'zh': '复习'},
    'speaking': {'en': 'Role Play', 'ko': '상황극 연습', 'zh': '角色扮演'},
    
    'priority': {'en': 'PRIORITY', 'ko': '지금 중요한 일', 'zh': '首要任务'},
    'schedule': {'en': 'Briefing', 'ko': '브리핑', 'zh': '简报'},
    'email': {'en': 'Summary', 'ko': '요약', 'zh': '摘要'},
    'logs': {'en': 'LOGS', 'ko': '최근 활동', 'zh': '最近活动'},
    'contract_sent': {'en': 'Task Done', 'ko': '업무 완료', 'zh': '任务完成'},
  };

  static String t(String key) {
    return _db[key]?[_language] ?? _db[key]?['en'] ?? key;
  }
}