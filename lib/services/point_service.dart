import 'package:shared_preferences/shared_preferences.dart';

class PointService {
  static final PointService _instance = PointService._internal();
  factory PointService() => _instance;
  PointService._internal();

  int _currentPoints = 30;
  int _nextRefillAmount = 29;

  Future<void> loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    String todayDate = DateTime.now().toString().split(' ')[0];
    String? lastDate = prefs.getString('last_access_date');

    // ★ 자정 지났으면 30개로 쿨하게 초기화
    if (lastDate != todayDate) {
      _currentPoints = 30;
      _nextRefillAmount = 29; 
      await prefs.setString('last_access_date', todayDate);
      await _save();
    } else {
      _currentPoints = prefs.getInt('user_points') ?? 30;
      _nextRefillAmount = prefs.getInt('next_refill') ?? 29;
    }
  }

  int get currentPoints => _currentPoints;

  Future<bool> usePoint() async {
    if (_currentPoints > 0) {
      _currentPoints--;
      await _save();
      return true;
    }
    return false;
  }

  // ★ 악마의 페널티 리필 (29..28..24->30)
  Future<void> refillPointsByAd() async {
    _currentPoints = _nextRefillAmount;
    if (_nextRefillAmount > 24) {
      _nextRefillAmount--;
    } else {
      _nextRefillAmount = 30;
    }
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_points', _currentPoints);
    await prefs.setInt('next_refill', _nextRefillAmount);
  }
}