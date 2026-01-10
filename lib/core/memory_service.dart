// lib/core/memory_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MemoryService {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  // 1. 대화 내역
  Future<void> saveChat(List<Map<String, String>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('luna_chat_history', jsonEncode(history));
  }

  Future<List<Map<String, String>>> loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('luna_chat_history');
    if (data == null) return [];
    List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  // 2. 8대 기능 전용 저장소 (에러 해결: addItem, getItems 추가)
  Future<void> addItem(String key, String content) async {
    final prefs = await SharedPreferences.getInstance();
    String storageKey = 'luna_data_$key'; 
    List<String> items = prefs.getStringList(storageKey) ?? [];
    
    // 날짜|내용 형식
    String timestamp = DateTime.now().toString().substring(0, 16);
    items.insert(0, "$timestamp|$content"); 
    
    await prefs.setStringList(storageKey, items);
  }

  Future<List<Map<String, String>>> getItems(String key) async {
    final prefs = await SharedPreferences.getInstance();
    String storageKey = 'luna_data_$key';
    List<String> items = prefs.getStringList(storageKey) ?? [];
    
    return items.map((item) {
      final parts = item.split('|');
      return {
        'date': parts[0],
        'content': parts.length > 1 ? parts[1] : parts[0]
      };
    }).toList();
  }
}