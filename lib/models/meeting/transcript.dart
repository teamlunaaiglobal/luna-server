class TranscriptSegment {
  final String speaker;      // 화자 (Speaker 1, Speaker 2...)
  final String text;         // 발화 내용
  final Duration startTime;  // 시작 시간
  final Duration endTime;    // 종료 시간
  final double confidence;   // 신뢰도

  TranscriptSegment({
    required this.speaker,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toMap() => {
    'speaker': speaker,
    'text': text,
    'startTime': startTime.inMilliseconds,
    'endTime': endTime.inMilliseconds,
    'confidence': confidence,
  };

  factory TranscriptSegment.fromMap(Map<String, dynamic> map) => TranscriptSegment(
    speaker: map['speaker'],
    text: map['text'],
    startTime: Duration(milliseconds: map['startTime']),
    endTime: Duration(milliseconds: map['endTime']),
    confidence: map['confidence'] ?? 1.0,
  );
}

class Transcript {
  final String meetingId;
  final List<TranscriptSegment> segments;
  final String fullText;
  final DateTime createdAt;

  Transcript({
    required this.meetingId,
    required this.segments,
    required this.fullText,
    required this.createdAt,
  });

  /// 화자별 발화 그룹핑
  Map<String, List<TranscriptSegment>> getBySpeaker() {
    final result = <String, List<TranscriptSegment>>{};
    for (var seg in segments) {
      result.putIfAbsent(seg.speaker, () => []).add(seg);
    }
    return result;
  }
}