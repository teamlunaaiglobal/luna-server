import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meeting/meeting_record.dart';
import '../models/meeting/action_item.dart';

class MeetingRepository {
  static final MeetingRepository instance = MeetingRepository._internal();
  factory MeetingRepository() => instance;
  MeetingRepository._internal();

  static const String _meetingsKey = 'luna_meetings';
  static const String _actionItemsKey = 'luna_action_items';
  
  List<MeetingRecord> _meetings = [];
  List<ActionItem> _actionItems = [];

  List<MeetingRecord> get allMeetings => _meetings;
  List<ActionItem> get allActionItems => _actionItems;

  /// 초기화
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 회의 로드
    final meetingsData = prefs.getString(_meetingsKey);
    if (meetingsData != null) {
      final List<dynamic> jsonList = jsonDecode(meetingsData);
      _meetings = jsonList.map((json) => MeetingRecord.fromMap(json)).toList();
    }
    
    // 액션 아이템 로드
    final actionsData = prefs.getString(_actionItemsKey);
    if (actionsData != null) {
      final List<dynamic> jsonList = jsonDecode(actionsData);
      _actionItems = jsonList.map((json) => ActionItem.fromMap(json)).toList();
    }
  }

  /// 회의 저장
  Future<void> _saveMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _meetings.map((m) => m.toMap()).toList();
    await prefs.setString(_meetingsKey, jsonEncode(jsonList));
  }

  /// 액션 아이템 저장
  Future<void> _saveActionItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _actionItems.map((a) => a.toMap()).toList();
    await prefs.setString(_actionItemsKey, jsonEncode(jsonList));
  }

  /// 회의 추가
  Future<void> addMeeting(MeetingRecord meeting) async {
    _meetings.add(meeting);
    await _saveMeetings();
  }

  /// 회의 업데이트
  Future<void> updateMeeting(MeetingRecord meeting) async {
    final index = _meetings.indexWhere((m) => m.id == meeting.id);
    if (index != -1) {
      _meetings[index] = meeting;
      await _saveMeetings();
    }
  }

  /// 회의 삭제
  Future<void> deleteMeeting(String id) async {
    _meetings.removeWhere((m) => m.id == id);
    _actionItems.removeWhere((a) => a.meetingId == id);
    await _saveMeetings();
    await _saveActionItems();
  }

  /// 회의 조회
  MeetingRecord? getMeeting(String id) {
    return _meetings.where((m) => m.id == id).firstOrNull;
  }

  /// 최근 회의 조회
  List<MeetingRecord> getRecentMeetings({int limit = 10}) {
    final sorted = List<MeetingRecord>.from(_meetings)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(limit).toList();
  }

  /// 액션 아이템 추가
  Future<void> addActionItem(ActionItem item) async {
    _actionItems.add(item);
    await _saveActionItems();
  }

  /// 액션 아이템 업데이트
  Future<void> updateActionItem(ActionItem item) async {
    final index = _actionItems.indexWhere((a) => a.id == item.id);
    if (index != -1) {
      _actionItems[index] = item;
      await _saveActionItems();
    }
  }

  /// 회의별 액션 아이템 조회
  List<ActionItem> getActionItemsByMeeting(String meetingId) {
    return _actionItems.where((a) => a.meetingId == meetingId).toList();
  }

  /// 미완료 액션 아이템 조회
  List<ActionItem> getPendingActionItems() {
    return _actionItems.where((a) => a.status != ActionItemStatus.completed).toList();
  }
}