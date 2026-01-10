import 'package:flutter/material.dart';
import '../core/memory_service.dart';

class ModeDetailPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final String desc;

  const ModeDetailPage({
    super.key,
    required this.title,
    required this.icon,
    required this.desc,
  });

  @override
  State<ModeDetailPage> createState() => _ModeDetailPageState();
}

class _ModeDetailPageState extends State<ModeDetailPage> {
  final MemoryService _memory = MemoryService();
  List<Map<String, String>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    String key = 'capture';
    String t = widget.title;

    // [수정] if문에 중괄호를 넣어 문법 에러 해결
    if (t.contains("회의")) {
      key = 'meeting';
    } else if (t.contains("일정")) {
      key = 'schedule';
    } else if (t.contains("문서")) {
      key = 'doc';
    } else if (t.contains("메일")) {
      key = 'mail';
    } else if (t.contains("리서치")) {
      key = 'research';
    } else if (t.contains("개인")) {
      key = 'personal';
    } else if (t.contains("공유")) {
      key = 'share';
    }
    
    final items = await _memory.getItems(key);
    
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty 
          ? const Center(child: Text("기록이 없습니다."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 40,
                        decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_items[index]['content']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(_items[index]['date']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}