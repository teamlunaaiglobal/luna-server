enum ActionItemPriority {
  high,
  medium,
  low,
}

enum ActionItemStatus {
  pending,
  inProgress,
  completed,
}

class ActionItem {
  final String id;
  final String meetingId;
  final String content;           // 할일 내용
  final String? assignee;         // 담당자
  final DateTime? dueDate;        // 마감일
  final ActionItemPriority priority;
  final ActionItemStatus status;
  final String? extractedFrom;    // 추출된 원문

  ActionItem({
    required this.id,
    required this.meetingId,
    required this.content,
    this.assignee,
    this.dueDate,
    this.priority = ActionItemPriority.medium,
    this.status = ActionItemStatus.pending,
    this.extractedFrom,
  });

  ActionItem copyWith({
    String? content,
    String? assignee,
    DateTime? dueDate,
    ActionItemPriority? priority,
    ActionItemStatus? status,
  }) {
    return ActionItem(
      id: id,
      meetingId: meetingId,
      content: content ?? this.content,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      extractedFrom: extractedFrom,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'meetingId': meetingId,
    'content': content,
    'assignee': assignee,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.index,
    'status': status.index,
    'extractedFrom': extractedFrom,
  };

  factory ActionItem.fromMap(Map<String, dynamic> map) => ActionItem(
    id: map['id'],
    meetingId: map['meetingId'],
    content: map['content'],
    assignee: map['assignee'],
    dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    priority: ActionItemPriority.values[map['priority'] ?? 1],
    status: ActionItemStatus.values[map['status'] ?? 0],
    extractedFrom: map['extractedFrom'],
  );
}