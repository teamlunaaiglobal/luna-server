// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/luen_colors.dart';
import 'tabs/home_tab.dart'; 
import 'tabs/menu_tab.dart';
import '../modules/system_module.dart'; 
import '../core/luna_processor.dart';
import '../services/hardware/luna_hearing_service.dart';
import '../services/hardware/luna_tts_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController(); 
  late AnimationController _breatheController;

  final LunaProcessor _processor = LunaProcessor.instance;
  final LunaHearingService _hearing = LunaHearingService.instance;
  final LunaTTSService _tts = LunaTTSService.instance;

  final SystemModule _systemModule = SystemModule(core: LunaProcessor.instance);

  String _orbState = 'idle'; 
  bool _isKeyboardVisible = false; 
  List<Map<String, dynamic>> chatHistory = [];
  int _currentTabIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initSystem();
    _breatheController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  Future<void> _initSystem() async {
    await _processor.init();
    await _hearing.init();
    await _tts.init();
    _addMessage("System Online. 준비되었습니다.", "luna");
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _hearing.stopListening();
    _tts.stop();
    super.dispose();
  }

  void _addMessage(String text, String sender) {
    setState(() {
      chatHistory.add({'text': text, 'sender': sender});
    });
    if (sender == 'me') {
       _systemModule.increaseUsage();
       setState(() {}); 
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTextInput(String text) async {
    if (text.trim().isEmpty) return;
    _addMessage(text, "me");
    _textController.clear();
    setState(() => _isKeyboardVisible = false); 
    setState(() => _orbState = 'thinking');
    String response = await _processor.processInput(text);
    _addMessage(response, "luna");
    setState(() => _orbState = 'idle');
  }

  void _toggleMic() {
    setState(() => _orbState = _orbState == 'idle' ? 'listening' : 'idle');
    if (_orbState == 'listening') _addMessage("듣고 있어요...", "system");
  }

  void _onCameraTap() {
     _addMessage("시각 분석을 시작합니다.", "luna");
  }

  void _toggleKeyboard() {
    setState(() => _isKeyboardVisible = !_isKeyboardVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep, 
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentTabIndex = index),
            children: [
              HomeTab(
                orbState: _orbState,
                chatHistory: chatHistory,
                onMicTap: _toggleMic,
                onCameraTap: _onCameraTap,
                onKeyboardTap: _toggleKeyboard, 
                breatheController: _breatheController,
                scrollController: _scrollController,
              ),
              MenuTab(systemModule: _systemModule),
            ],
          ),

          if (_currentTabIndex == 0)
            Positioned(
              top: 50, 
              right: 25,
              child: Container(
                padding: const EdgeInsets.all(8), 
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: const RotatedBox(
                  quarterTurns: 3, 
                  child: Icon(Icons.battery_full, color: Colors.grey, size: 26),
                ),
              ),
            ),

          if (!_isKeyboardVisible) 
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentTabIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      // [수정 완료] 형광색 뺌! 선택되면 흰색, 아니면 어두운 회색
                      color: _currentTabIndex == index ? Colors.white : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          if (_isKeyboardVisible)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "메시지 입력...",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: const Color(0xFF111111),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onSubmitted: _handleTextInput,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: LuenColors.neonPoint),
                      onPressed: () => _handleTextInput(_textController.text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => setState(() => _isKeyboardVisible = false),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}