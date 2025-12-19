import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../luen_colors.dart';
import '../services/lang.dart';
import '../util/action_handler.dart'; 
import '../data/menu_data.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // [UI 컨트롤러]
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _breatheController;

  // [음성 및 TTS]
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  // [상태 변수]
  String _orbState = 'idle'; // idle, listening, speaking, thinking
  bool _isKeyboardVisible = false;
  double _currentPageValue = 0.0;
  bool _isSpeechAvailable = false;
  
  // [대화 기록]
  List<Map<String, String>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    _initSystem();
    
    _breatheController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pageController.addListener(() {
      setState(() { _currentPageValue = _pageController.page ?? 0.0; });
    });
  }

  Future<void> _initSystem() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    
    _isSpeechAvailable = await _speech.initialize(
      onError: (e) => debugPrint("STT Error: $e"),
    );
    
    await _flutterTts.setLanguage("ko-KR");
    
    _addMessage(Lang.t('system_online'), "luna");
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pageController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  // --- [기능 로직] ---

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _addMessage(String text, String sender) {
    setState(() {
      chatHistory.add({
        'text': text, 
        'sender': sender, 
        'time': "${DateTime.now().hour}:${DateTime.now().minute}"
      });
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _toggleMic() async {
    if (!_isSpeechAvailable) return;

    if (_speech.isListening) {
      _speech.stop();
      setState(() => _orbState = 'idle');
    } else {
      setState(() => _orbState = 'listening');
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            _handleUserInput(val.recognizedWords);
            setState(() => _orbState = 'idle');
          }
        },
        localeId: "ko-KR",
      );
    }
  }

  void _handleUserInput(String input) {
    if (input.trim().isEmpty) return;
    
    _addMessage(input, 'me'); 

    // 1. ActionHandler 확인
    String? actionId;
    
    // [수정] 모든 if문에 중괄호 {}를 적용하여 경고 제거
    if (input.contains("타이머")) {
      actionId = "tool_timer";
    } else if (input.contains("녹음")) {
      actionId = "tool_record";
    } else if (input.contains("카메라")) {
      actionId = "tool_scan";
    } else if (input.contains("지도")) {
      actionId = "app_map";
    } else if (input.contains("메모")) {
      actionId = "quick_text_memo";
    }

    if (actionId != null) {
      setState(() => _orbState = 'speaking');
      _flutterTts.speak("확인했습니다.");
      
      ActionHandler.execute(context, actionId, input);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _orbState = 'idle');
      });
      return;
    }

    // 2. 일반 대화
    setState(() => _orbState = 'thinking');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        String reply = "제가 도울 수 있는 일을 말씀해주세요. (예: 타이머 켜줘)";
        _addMessage(reply, 'luna');
        _flutterTts.speak(reply);
        setState(() => _orbState = 'idle');
      }
    });
  }

  // --- [UI 빌드] ---
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    double orbTop = (screenSize.height * 0.18) - (_currentPageValue * 50);
    double orbScale = 1.0 - (_currentPageValue * 0.5); 
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: LuenColors.bgDeep,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 배경
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center, radius: 1.5,
                  colors: [Color(0xFF1A1F3D), Color(0xFF050508)],
                ),
              ),
            ),
          ),
          
          // 2. 루나 오브
          Positioned(
            top: orbTop, left: 0, right: 0,
            child: Center(
              child: Transform.scale(scale: orbScale, child: _buildLivingOrb()),
            ),
          ),
          
          // 3. 페이지 뷰
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              children: [
                _buildChatPage(screenSize),      // 1페이지
                _buildDashboardPage(screenSize), // 2페이지
              ],
            ),
          ),

          // 4. 상단 정보
          Positioned(
            top: statusBarHeight + 10,
            left: 0, right: 0,
            child: Column(
              children: [
                Text(Lang.t('luna'), style: const TextStyle(color: Colors.white24, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold)),
                if (_orbState == 'listening')
                  Text("● ${Lang.t('rec')}", style: const TextStyle(color: LuenColors.micRed, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),

          // 5. 하단 독
          if (!_isKeyboardVisible)
             Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomDock()),
             
          // 6. 키보드 입력창
          if (_isKeyboardVisible) 
            Positioned(bottom: 0, left: 0, right: 0, child: _buildInputArea()),
        ],
      ),
    );
  }

  Widget _buildLivingOrb() {
    Color coreColor = Colors.blue;
    if (_orbState == 'listening') coreColor = Colors.red;
    if (_orbState == 'speaking') coreColor = Colors.cyan;
    if (_orbState == 'thinking') coreColor = Colors.purple;

    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.8),
                coreColor.withValues(alpha: 0.6), 
                Colors.transparent
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: coreColor.withValues(alpha: 0.3), 
                blurRadius: 40 + (20 * _breatheController.value)
              )
            ]
          ),
        );
      }
    );
  }

  Widget _buildChatPage(Size size) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(top: size.height * 0.45, left: 20, right: 20, bottom: 120),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final msg = chatHistory[index];
        bool isMe = msg['sender'] == 'me';
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(msg['text']!, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildDashboardPage(Size size) {
    final items = LunaMenuData.getFunctions("비서") + LunaMenuData.getFunctions("도구");
    return GridView.builder(
      padding: EdgeInsets.only(top: size.height * 0.25, left: 20, right: 20, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => ActionHandler.execute(context, item.actionId, item.title),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: Colors.blueAccent, size: 30),
                const SizedBox(height: 8),
                Text(item.title, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomDock() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100,
          color: Colors.black.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.keyboard, color: Colors.white70), onPressed: () => setState(() => _isKeyboardVisible = true)),
              GestureDetector(
                onTap: _toggleMic,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: _orbState == 'listening' ? Colors.red : Colors.blue,
                  child: const Icon(Icons.mic, color: Colors.white),
                ),
              ),
              IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white70), onPressed: () {
                 ActionHandler.execute(context, "tool_scan", "카메라");
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: const Color(0xFF0B0B0E),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "명령 입력...",
                hintStyle: const TextStyle(color: Colors.white38),
                fillColor: Colors.white.withValues(alpha: 0.1),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onSubmitted: (t) { 
                _handleUserInput(t); 
                _textController.clear(); 
                setState(() => _isKeyboardVisible = false);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white), 
            onPressed: () => setState(() => _isKeyboardVisible = false)
          ),
        ],
      ),
    );
  }
}