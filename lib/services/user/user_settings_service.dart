import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsService {
  static final UserSettingsService instance = UserSettingsService._internal();
  factory UserSettingsService() => instance;
  UserSettingsService._internal();

  SharedPreferences? _prefs;
  
  // === 유저 기본 설정 (자국) ===
  String homeLanguage = 'en';       // 자국어
  String homeTimezone = 'UTC';      // 자국 시간대
  
  // === 현재 위치 기반 (여행 등) ===
  String currentTimezone = 'UTC';   // 현재 시간대
  String currentLocale = 'en';      // 현지 언어 (준비용)
  
  // === 학습용 ===
  String targetLanguage = 'en';     // 학습할 외국어
  
  bool isFirstRun = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    isFirstRun = _prefs?.getBool('isFirstRun') ?? true;
    
    if (isFirstRun) {
      // 최초 실행 - 폰에서 자동 감지
      await _detectSystemSettings();
      // 최초에는 현재 위치 = 자국으로 설정
      homeTimezone = currentTimezone;
      homeLanguage = currentLocale;
      await _saveHomeSettings();
      await _prefs?.setBool('isFirstRun', false);
    } else {
      // 기존 유저 - 저장된 설정 로드
      _loadSavedSettings();
      // 현재 위치는 항상 새로 감지
      _detectCurrentLocation();
    }
  }

  void _loadSavedSettings() {
    homeLanguage = _prefs?.getString('homeLanguage') ?? 'en';
    homeTimezone = _prefs?.getString('homeTimezone') ?? 'UTC';
    targetLanguage = _prefs?.getString('targetLanguage') ?? 'en';
  }

  Future<void> _detectSystemSettings() async {
    _detectCurrentLocation();
  }

  void _detectCurrentLocation() {
    // 폰 시스템 언어 감지
    Locale systemLocale = PlatformDispatcher.instance.locale;
    currentLocale = systemLocale.languageCode;
    
    // 현재 시간대 감지
    currentTimezone = DateTime.now().timeZoneName;
  }

  Future<void> _saveHomeSettings() async {
    await _prefs?.setString('homeLanguage', homeLanguage);
    await _prefs?.setString('homeTimezone', homeTimezone);
  }

  // 해외 여행 중인지 확인
  bool isAbroad() {
    return currentTimezone != homeTimezone;
  }

  // 현재 시간대 기반 인사말 타입
  String getGreetingType() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  // 언어 코드 → 언어 이름
  String getLanguageName(String code) {
    Map<String, String> names = {
      'ko': 'Korean', 'en': 'English', 'ja': 'Japanese',
      'zh': 'Chinese', 'es': 'Spanish', 'fr': 'French',
      'de': 'German', 'pt': 'Portuguese', 'it': 'Italian',
      'ru': 'Russian', 'ar': 'Arabic', 'hi': 'Hindi',
      'th': 'Thai', 'vi': 'Vietnamese', 'id': 'Indonesian',
    };
    return names[code] ?? code;
  }

  // 설정 저장
  Future<void> setHomeLanguage(String lang) async {
    homeLanguage = lang;
    await _prefs?.setString('homeLanguage', lang);
  }

  Future<void> setTargetLanguage(String lang) async {
    targetLanguage = lang;
    await _prefs?.setString('targetLanguage', lang);
  }

  Future<void> setHomeTimezone(String tz) async {
    homeTimezone = tz;
    await _prefs?.setString('homeTimezone', tz);
  }
}
