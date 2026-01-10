import 'package:flutter/foundation.dart';
import '../emotion_engine.dart';
import '../../models/meeting/action_item.dart';

class ActionItemExtractor {
  static final ActionItemExtractor instance = ActionItemExtractor._internal();
  factory ActionItemExtractor() => instance;
  ActionItemExtractor._internal();

  final LunaBrain _brain = LunaBrain();

  /// 회의록에서 액션 아이템 추출
  Future<List<ActionItem>> extract(String transcript, String meetingId) async {
    if (transcript.isEmpty) return [];

    final prompt = '''
아래 회의 내용에서 할일(액션 아이템)을 추출해줘.

$transcript

---

다음 형식으로 답해줘 (각 줄에 하나씩):
[담당자] 할일 내용 | 우선순위(상/중/하)

담당자를 알 수 없으면 [미정]으로 써줘.
할일이 없으면 "없음"이라고만 답해줘.
''';

    try {
      final result = await _brain.getResponse(prompt);
      
      if (result.contains('없음')) {
        return [];
      }

      return _parseActionItems(result, meetingId);
    } catch (e) {
      debugPrint('❌ 액션 아이템 추출 실패: $e');
      return [];
    }
  }

  /// AI 응답 파싱
  List<ActionItem> _parseActionItems(String response, String meetingId) {
    final items = <ActionItem>[];
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty);

    for (var line in lines) {
      try {
        // [담당자] 할일 | 우선순위 형식 파싱
        String? assignee;
        String content = line;
        ActionItemPriority priority = ActionItemPriority.medium;

        // 담당자 추출
        final assigneeMatch = RegExp(r'\[([^\]]+)\]').firstMatch(line);
        if (assigneeMatch != null) {
          assignee = assigneeMatch.group(1);
          if (assignee == '미정') assignee = null;
          content = line.replaceFirst(assigneeMatch.group(0)!, '').trim();
        }

        // 우선순위 추출
        if (content.contains('|')) {
          final parts = content.split('|');
          content = parts[0].trim();
          final priorityStr = parts[1].trim();
          
          if (priorityStr.contains('상') || priorityStr.toLowerCase().contains('high')) {
            priority = ActionItemPriority.high;
          } else if (priorityStr.contains('하') || priorityStr.toLowerCase().contains('low')) {
            priority = ActionItemPriority.low;
          }
        }

        if (content.isNotEmpty) {
          items.add(ActionItem(
            id: '${meetingId}_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
            meetingId: meetingId,
            content: content,
            assignee: assignee,
            priority: priority,
            extractedFrom: line,
          ));
        }
      } catch (e) {
        debugPrint('⚠️ 라인 파싱 실패: $line');
      }
    }

    debugPrint('✅ ${items.length}개 액션 아이템 추출');
    return items;
  }

  /// 자연어에서 액션 아이템 감지 (실시간용)
  bool detectActionItem(String text) {
    final patterns = [
      '내가 할게',
      '내가 해',
      '제가 할게',
      '제가 해',
      '해야 해',
      '해야겠',
      '해주세요',
      '부탁드려',
      '확인해',
      '검토해',
      '준비해',
      '보내',
      '정리해',
      '공유해',
    ];
    
    final lower = text.toLowerCase();
    return patterns.any((p) => lower.contains(p));
  }

  /// 단일 문장에서 액션 아이템 추출 (실시간용)
  ActionItem? extractSingle(String text, String meetingId) {
    if (!detectActionItem(text)) return null;

    // 간단한 추출 (AI 없이)
    String content = text
        .replaceAll(RegExp(r'(내가|제가)\s*(할게|해|하겠)'), '')
        .replaceAll(RegExp(r'해야\s*(해|겠|합니다)'), '')
        .trim();

    if (content.isEmpty) return null;

    return ActionItem(
      id: '${meetingId}_${DateTime.now().millisecondsSinceEpoch}',
      meetingId: meetingId,
      content: content,
      extractedFrom: text,
    );
  }
}
