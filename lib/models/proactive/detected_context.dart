enum ContextType {
  meeting,      // 회의 관련
  dining,       // 회식/식사
  task,         // 할일 감지
  schedule,     // 일정 언급
  anniversary,  // 기념일
  travel,       // 여행
  none,
}

class DetectedContext {
  final ContextType type;
  final String keyword;        // 감지된 키워드
  final String originalText;   // 원본 문장
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;  // 추가 정보 (날짜, 장소 등)

  DetectedContext({
    required this.type,
    required this.keyword,
    required this.originalText,
    required this.detectedAt,
    this.metadata,
  });
}