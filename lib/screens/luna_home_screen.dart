import 'package:flutter/material.dart';
import '../services/luna_unified_block.dart';

class LunaHomeScreen extends StatefulWidget {
  const LunaHomeScreen({super.key});

  @override
  State<LunaHomeScreen> createState() => _LunaHomeScreenState();
}

class _LunaHomeScreenState extends State<LunaHomeScreen> {
  // [수정] UnifiedBlock 싱글톤 호출
  final LunaUnifiedBlock _lunaBlock = LunaUnifiedBlock();
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  @override
  void dispose() {
    // 메모리 최적화
    _textController.dispose();
    _scrollController.dispose();
    // TTS 등 리소스 정리
    _lunaBlock.stopAll();
    super.dispose();
  }

  Future<void> _initSystem() async {
    await _lunaBlock.init();
    
    // 초기 환영 메시지 (필요 시 활성화)
    // String welcome = await _lunaBlock.welcomeMessage();
    // _addMessage('luna', welcome);
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    _addMessage('user', text);

    setState(() {
      _isLoading = true;
    });

    try {
      // [수정] friendMode 호출 (기본 대화)
      // 특정 키워드(예: "일정", "업무") 감지 시 assistantMode 호출 로직 추가 가능
      String response = await _lunaBlock.friendMode(text);
      
      _addMessage('luna', response);
    } catch (e) {
      _addMessage('system', 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({'sender': sender, 'text': text});
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("LUNA", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                           const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.smart_toy, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Container(
                            // 텍스트 가독성을 위한 최소한의 패딩 (말풍선 아님)
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isUser ? Colors.black87 : Colors.black54,
                                fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                              ),
                              textAlign: isUser ? TextAlign.right : TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "Message Luna...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}