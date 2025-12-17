import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/luna_unified_block.dart';
import '../services/ad_service.dart';
import '../services/lang.dart';

class ChatPage extends StatefulWidget {
  final VoidCallback onNavigateToAssistant;
  const ChatPage({super.key, required this.onNavigateToAssistant});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final LunaUnifiedBlock _lunaBlock = LunaUnifiedBlock();
  final AdService _adService = AdService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final List<Map<String, String>> _chatHistory = [];
  
  bool _isTyping = false;
  bool _isListening = false;
  
  // [수정] 경고 무시 코드 추가 (나중에 기능 구현 시 제거 가능)
  // ignore: prefer_final_fields
  int _points = 100; 

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initSystem();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _lunaBlock.stopAll();
    super.dispose();
  }

  void _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _initSystem() async {
    await _lunaBlock.init();
    _adService.loadAd();
    _addMessage("Luna", "Hello! I am ready.");
  }

  void _addMessage(String user, String text) {
    if (!mounted) return;
    setState(() => _chatHistory.add({'user': user, 'text': text}));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _processInput(String input) async {
    if (input.trim().isEmpty) return;
    await _lunaBlock.stopAll();

    _addMessage("You", input);
    setState(() => _isTyping = true);

    String response = await _lunaBlock.handleInputAuto(input);
    
    if (!mounted) return;
    setState(() => _isTyping = false);
    _addMessage("Luna", response);
  }

  void _onMic() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (r) {
            if (r.finalResult) _processInput(r.recognizedWords);
          },
          localeId: Lang.ttsCode 
        );
      }
    }
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg['user'] == 'You';
    final text = msg['text'] ?? "";

    return ListTile(
      title: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.blueGrey[700] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
               BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)
            ]
          ),
          child: MarkdownBody(
            data: text,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.bolt, color: Colors.amber[700], size: 20),
              const SizedBox(width: 5),
              Text("$_points", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[900])),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _chatHistory.length,
            itemBuilder: (c, i) => _buildChatBubble(_chatHistory[i]),
          ),
        ),
        if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: Text("Luna is thinking...")),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (v){_processInput(v); _textController.clear();},
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none)
                ),
              )
            ),
            IconButton(icon: Icon(_isListening ? Icons.mic : Icons.mic_none), onPressed: _onMic),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueGrey),
              onPressed: (){_processInput(_textController.text); _textController.clear();}
            ),
          ]),
        )
      ],
    );
  }
}