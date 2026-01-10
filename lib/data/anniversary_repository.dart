import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/proactive/anniversary.dart';

class AnniversaryRepository {
  static final AnniversaryRepository instance = AnniversaryRepository._internal();
  factory AnniversaryRepository() => instance;
  AnniversaryRepository._internal();

  static const String _storageKey = 'luna_anniversaries';
  List<Anniversary> _anniversaries = [];

  List<Anniversary> get all => _anniversaries;

  /// 초기화 - 저장된 기념일 로드
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _anniversaries = jsonList.map((json) => Anniversary(
        id: json['id'],
        name: json['name'],
        type: AnniversaryType.values[json['type']],
        month: json['month'],
        day: json['day'],
        year: json['year'],
        isLunar: json['isLunar'] ?? false,
        checklist: List<String>.from(json['checklist'] ?? []),
      )).toList();
    }
  }

  /// 저장
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _anniversaries.map((a) => {
      'id': a.id,
      'name': a.name,
      'type': a.type.index,
      'month': a.month,
      'day': a.day,
      'year': a.year,
      'isLunar': a.isLunar,
      'checklist': a.checklist,
    }).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// 기념일 추가
  Future<void> add(Anniversary anniversary) async {
    _anniversaries.add(anniversary);
    await _save();
  }

  /// 기념일 삭제
  Future<void> delete(String id) async {
    _anniversaries.removeWhere((a) => a.id == id);
    await _save();
  }

  /// 기념일 수정
  Future<void> update(Anniversary anniversary) async {
    final index = _anniversaries.indexWhere((a) => a.id == anniversary.id);
    if (index != -1) {
      _anniversaries[index] = anniversary;
      await _save();
    } 
  }

  /// 다가오는 기념일 (D-day 기준 정렬)
  List<Anniversary> getUpcoming({int withinDays = 30}) {
    return _anniversaries
        .where((a) => a.getDday() <= withinDays)
        .toList()
      ..sort((a, b) => a.getDday().compareTo(b.getDday()));
  }

  /// 오늘인 기념일
  List<Anniversary> getToday() {
    return _anniversaries.where((a) => a.getDday() == 0).toList();
  }

  /// 긴급 (D-3 이내)
  List<Anniversary> getUrgent() {
    return _anniversaries.where((a) => a.getDday() <= 3 && a.getDday() >= 0).toList();
  }
}
