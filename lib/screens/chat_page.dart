import 'package:flutter/material.dart';
import '../services/luna_unified_block.dart'; // 통합 두뇌 연결

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() { _messages.add({"role": "user", "text": text}); });
    _controller.clear();

    // [핵심] 여기서 루나의 뇌(UnifiedBlock)로 전달
    String response = await LunaUnifiedBlock().handleInputAuto(text);

    if (mounted) {
      setState(() { _messages.add({"role": "luna", "text": response}); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Luna AI Interface")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Align(
                  alignment: _messages[i]['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _messages[i]['role'] == 'user' ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_messages[i]['text']!),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "대화 입력...",
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}