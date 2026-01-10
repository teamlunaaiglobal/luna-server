import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

/// 대화 메시지 모델
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final String emotion; // 감정 태그
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.emotion,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role,
    'text': text,
    'emotion': emotion,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata != null ? jsonEncode(metadata) : null,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'],
    role: map['role'],
    text: map['text'],
    emotion: map['emotion'] ?? 'neutral',
    timestamp: DateTime.parse(map['timestamp']),
    metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
  );
}

/// 대화 요약 모델
class ConversationSummary {
  String userProfile; // "개발자, 야근 많음"
  String recentTopics; // "이직 고민, 프로젝트 스트레스"
  String emotionalState; // "최근 지쳐있음"
  DateTime lastUpdated;

  ConversationSummary({
    this.userProfile = '',
    this.recentTopics = '',
    this.emotionalState = '',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'userProfile': userProfile,
    'recentTopics': recentTopics,
    'emotionalState': emotionalState,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ConversationSummary.fromMap(Map<String, dynamic> map) => ConversationSummary(
    userProfile: map['userProfile'] ?? '',
    recentTopics: map['recentTopics'] ?? '',
    emotionalState: map['emotionalState'] ?? '',
    lastUpdated: map['lastUpdated'] != null 
        ? DateTime.parse(map['lastUpdated']) 
        : DateTime.now(),
  );

  /// 서버 전송용 압축 문자열
  String toCompressed() => "$userProfile|$recentTopics|$emotionalState";
}

/// ============================================================
/// 하이브리드 대화 기억 시스템 (Hive + SQLite)
/// ============================================================
class ConversationMemory {
  static final ConversationMemory instance = ConversationMemory._internal();
  factory ConversationMemory() => instance;
  ConversationMemory._internal();

  // Hive (빠른 접근)
  late Box<Map> _recentBox;
  late Box<Map> _summaryBox;

  // SQLite (전체 기록)
  Database? _db;

  // 설정
  static const int maxRecentTurns = 50; // 최근 대화 저장 수
  static const int summaryInterval = 10; // N턴마다 요약 업데이트
  
  int _turnCount = 0;

  /// 초기화
  Future<void> init() async {
    // Hive 초기화
    await Hive.initFlutter();
    _recentBox = await Hive.openBox<Map>('recent_conversations');
    _summaryBox = await Hive.openBox<Map>('conversation_summary');
    
    // SQLite 초기화
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      path.join(dbPath, 'luna_memory.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            emotion TEXT,
            timestamp TEXT NOT NULL,
            metadata TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_timestamp ON conversations(timestamp)
        ''');
        await db.execute('''
          CREATE INDEX idx_emotion ON conversations(emotion)
        ''');
      },
    );
    
    debugPrint("📂 ConversationMemory 초기화 완료");
  }

  /// 메시지 저장 (Hive + SQLite 동시)
  Future<void> saveMessage(ChatMessage message) async {
    // 1. Hive에 최근 대화 저장 (빠름)
    List<Map> recent = _getRecentFromHive();
    recent.add(message.toMap());
    
    // 최대 개수 초과 시 오래된 것 제거
    if (recent.length > maxRecentTurns) {
      recent = recent.sublist(recent.length - maxRecentTurns);
    }
    await _recentBox.put('messages', {'list': recent});
    
    // 2. SQLite에 전체 기록 저장 (백그라운드)
    await _db?.insert('conversations', message.toMap());
    
    // 3. N턴마다 요약 업데이트
    _turnCount++;
    if (_turnCount >= summaryInterval) {
      _turnCount = 0;
      await _updateSummary();
    }
    
    debugPrint("💾 대화 저장: ${message.role} - ${message.text.substring(0, message.text.length.clamp(0, 20))}...");
  }

  /// 최근 대화 가져오기 (Hive에서 즉시)
  List<ChatMessage> getRecentMessages({int? limit}) {
    List<Map> recent = _getRecentFromHive();
    if (limit != null && recent.length > limit) {
      recent = recent.sublist(recent.length - limit);
    }
    return recent.map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  List<Map> _getRecentFromHive() {
    final data = _recentBox.get('messages');
    if (data == null) return [];
    return List<Map>.from(data['list'] ?? []);
  }

  /// 요약 가져오기
  ConversationSummary getSummary() {
    final data = _summaryBox.get('summary');
    if (data == null) return ConversationSummary();
    return ConversationSummary.fromMap(Map<String, dynamic>.from(data));
  }

  /// 요약 업데이트 (폰 AI 또는 간단한 로직으로)
  Future<void> _updateSummary() async {
    
    // 지금은 간단한 로직으로 대체
    
    List<ChatMessage> recent = getRecentMessages(limit: 20);
    if (recent.isEmpty) return;

    ConversationSummary summary = getSummary();
    
    // 최근 감정 분석
    Map<String, int> emotionCount = {};
    for (var msg in recent) {
      emotionCount[msg.emotion] = (emotionCount[msg.emotion] ?? 0) + 1;
    }
    String topEmotion = emotionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    summary.emotionalState = _emotionToKorean(topEmotion);
    summary.lastUpdated = DateTime.now();
    
    await _summaryBox.put('summary', summary.toMap());
    debugPrint("📝 요약 업데이트: ${summary.emotionalState}");
  }

  String _emotionToKorean(String emotion) {
    const map = {
      'tired': '지쳐있음',
      'sad': '우울함',
      'happy': '기분 좋음',
      'angry': '화남',
      'neutral': '평온함',
      'seeksEmotionalConnection': '외로움',
      'motivated': '의욕적',
    };
    return map[emotion] ?? '평온함';
  }

  /// 서버 전송용 컨텍스트 생성 (압축)
  String buildServerContext({int recentCount = 5}) {
    ConversationSummary summary = getSummary();
    List<ChatMessage> recent = getRecentMessages(limit: recentCount);
    
    // 압축 포맷: [요약]|[최근대화]
    String summaryStr = summary.toCompressed();
    String recentStr = recent.map((m) => 
      "${m.role[0]}:${m.text}"  // u:안녕 or a:반가워
    ).join(';');
    
    return "$summaryStr||$recentStr";
  }

  /// 날짜로 대화 검색 (SQLite)
  Future<List<ChatMessage>> searchByDate(DateTime start, DateTime end) async {
    if (_db == null) return [];
    
    final results = await _db!.query(
      'conversations',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    
    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  /// 감정으로 대화 검색 (SQLite)
  Future<List<ChatMessage>> searchByEmotion(String emotion) async {
    if (_db == null) return [];
    
    final results = await _db!.query(
      'conversations',
      where: 'emotion = ?',
      whereArgs: [emotion],
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    
    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  /// 키워드로 대화 검색 (SQLite)
  Future<List<ChatMessage>> searchByKeyword(String keyword) async {
    if (_db == null) return [];
    
    final results = await _db!.query(
      'conversations',
      where: 'text LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    
    return results.map((m) => ChatMessage.fromMap(m)).toList();
  }

  /// 전체 대화 수
  Future<int> getTotalCount() async {
    if (_db == null) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as cnt FROM conversations');
    return result.first['cnt'] as int;
  }

  /// 요약 수동 설정 (사용자 프로필 등)
  Future<void> updateUserProfile(String profile) async {
    ConversationSummary summary = getSummary();
    summary.userProfile = profile;
    summary.lastUpdated = DateTime.now();
    await _summaryBox.put('summary', summary.toMap());
  }

  /// 최근 토픽 수동 설정
  Future<void> updateRecentTopics(String topics) async {
    ConversationSummary summary = getSummary();
    summary.recentTopics = topics;
    summary.lastUpdated = DateTime.now();
    await _summaryBox.put('summary', summary.toMap());
  }
}