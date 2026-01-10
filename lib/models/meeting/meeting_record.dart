enum MeetingStatus {
  recording,   // 녹음 중
  processing,  // 처리 중 (STT/요약)
  completed,   // 완료
  failed,      // 실패
}

class MeetingRecord {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? audioPath;       // 녹음 파일 경로
  final String? transcript;      // 전사 결과
  final String? summary;         // AI 요약
  final List<String> participants;
  final MeetingStatus status;
  final Map<String, dynamic>? metadata;

  MeetingRecord({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.audioPath,
    this.transcript,
    this.summary,
    this.participants = const [],
    this.status = MeetingStatus.recording,
    this.metadata,
  });

  /// 녹음 시간 (분)
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inMinutes;
  }

  /// 복사 with 변경
  MeetingRecord copyWith({
    String? title,
    DateTime? endTime,
    String? audioPath,
    String? transcript,
    String? summary,
    List<String>? participants,
    MeetingStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return MeetingRecord(
      id: id,
      title: title ?? this.title,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      audioPath: audioPath ?? this.audioPath,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'audioPath': audioPath,
    'transcript': transcript,
    'summary': summary,
    'participants': participants,
    'status': status.index,
    'metadata': metadata,
  };

  factory MeetingRecord.fromMap(Map<String, dynamic> map) => MeetingRecord(
    id: map['id'],
    title: map['title'],
    startTime: DateTime.parse(map['startTime']),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    audioPath: map['audioPath'],
    transcript: map['transcript'],
    summary: map['summary'],
    participants: List<String>.from(map['participants'] ?? []),
    status: MeetingStatus.values[map['status'] ?? 0],
    metadata: map['metadata'],
  );
}