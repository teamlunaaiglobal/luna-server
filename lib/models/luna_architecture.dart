// lib/models/luna_architecture.dart

// [수정] Firestore 의존성 제거 (에러 방지)
// import 'package:cloud_firestore/cloud_firestore.dart';

enum LunaModeCategory {
  capture, meeting, document, schedule, email, research, personal, delivery,
}

class LunaInput {
  final String id;
  final String type;
  final String contentRaw;
  final DateTime createdAt;
  final String source;
  final String processingStatus;

  LunaInput({
    required this.id,
    required this.type,
    required this.contentRaw,
    required this.createdAt,
    this.source = 'app',
    this.processingStatus = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'content_raw': contentRaw,
    'created_at': createdAt.toIso8601String(), // [수정] Timestamp -> String
    'source': source,
    'processing_status': processingStatus,
  };
}

class LunaContext {
  final String id;
  final String summary;
  final List<String> keywords;
  final String sentiment;
  final String originalInputId;
  final LunaModeCategory relatedMode;

  LunaContext({
    required this.id,
    required this.summary,
    required this.keywords,
    required this.sentiment,
    required this.originalInputId,
    this.relatedMode = LunaModeCategory.capture,
  });
}

class LunaJudgement {
  final String id;
  final String targetType;
  final String targetId;
  final int scoreTotal;
  final Map<String, int> scoreDetails;
  final String decision;
  final String reasoning;

  LunaJudgement({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.scoreTotal,
    required this.scoreDetails,
    required this.decision,
    required this.reasoning,
  });
}