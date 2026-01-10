import '../../core/memory_service.dart';

class MemoService {
  static final MemoService instance = MemoService._internal();
  factory MemoService() => instance;
  MemoService._internal();

  final MemoryService _memory = MemoryService();

  /// 메모 저장
  Future<String> addMemo(String input) async {
    String content = input.replaceAll(RegExp(r'(메모해|기록해|적어|메모 추가|줘|해줘)'), '').trim();
    if (content.isNotEmpty) {
      await _memory.addItem('memo', content);
      return "메모했어! '$content'";
    }
    return "뭘 메모할까?";
  }

  /// 메모 조회
  Future<String> getMemos() async {
    var memos = await _memory.getItems('memo');
    if (memos.isEmpty) return "저장된 메모가 없어.";
    String list = memos.asMap().entries.map((e) => "${e.key + 1}. ${e.value['content']}").join('\n');
    return "네 메모 목록이야:\n$list";
  }

  /// 메모 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('메모해') || 
           lower.contains('기록해') || 
           lower.contains('적어') || 
           lower.contains('메모 추가') ||
           lower.contains('메모 보여') || 
           lower.contains('메모 뭐') || 
           lower.contains('메모 목록') || 
           lower.contains('메모 확인');
  }

  /// 메모 처리
  Future<String> handle(String input) async {
    final lower = input.toLowerCase();
    
    if (lower.contains('메모 보여') || lower.contains('메모 뭐') || 
        lower.contains('메모 목록') || lower.contains('메모 확인')) {
      return await getMemos();
    }
    
    return await addMemo(input);
  }
}
