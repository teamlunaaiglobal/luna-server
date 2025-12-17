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
    // BootService가 main에서 이미 init을 했으므로 여기선 호출 생략
  }

  @override
  void dispose() {
    // 메모리 최적화
    _textController.dispose();
    _scrollController.dispose();
    _lunaBlock.stopAll(); // 앱 끌 때 뇌 정지 (안전장치)
    super.dispose();
  }

  // [핵심 Logic] 메시지 전송 시 뇌(UnifiedBlock)로 전달
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    _addMessage('user', text);

    setState(() {
      _isLoading = true;
    });

    try {
      // [수정] 기존 friendMode() 대신 handleInputAuto() 사용
      // (UnifiedBlock 파일에 정의된 유일한 대화 처리 함수)
      String response = await _lunaBlock.handleInputAuto(text);
      
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
    
    // 자동 스크롤
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
      backgroundColor: const Color(0xFFF5F5F7), // 배경색 유지
      appBar: AppBar(
        title: const Text("LUNA", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 채팅 리스트 영역
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
                        // 루나 프로필 아이콘 (좌측)
                        if (!isUser) ...[
                           const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.smart_toy, size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // 말풍선
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[600] : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isUser ? Colors.white : Colors.black87,
                                fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 로딩 표시
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
            
            // 입력창 영역
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: "Message Luna...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
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