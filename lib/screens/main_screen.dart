// [Macroscopic Fix] 이 파일 전체에서 'const' 강요 규칙을 무시합니다.
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../luen_colors.dart';
import '../services/lang.dart';
import '../util/action_handler.dart'; 

// [New Architecture Imports]
import '../services/luna_processor.dart';
import '../services/hardware/luna_hearing_service.dart';
import '../services/hardware/luna_tts_service.dart';

// [Existing Modules]
import '../modules/teacher/ui/teacher_screen.dart';
import '../modules/teacher/services/learning_planner.dart';
import '../modules/teacher/services/conversation_evaluator.dart';
import '../modules/teacher/services/teacher_ai_service.dart';
import '../modules/teacher/models/study_material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // --- [Controllers] ---
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _breatheController;

  // --- [New Architecture Engines] ---
  final LunaProcessor _processor = LunaProcessor.instance;
  final LunaHearingService _hearing = LunaHearingService.instance;
  final LunaTTSService _tts = LunaTTSService.instance;

  // --- [State Variables] ---
  String _orbState = 'idle'; 
  bool _isKeyboardVisible = false;
  double _currentPageValue = 0.0;
  List<Map<String, dynamic>> chatHistory = [];

  // --- [AI Services] ---
  final LearningPlanner _planner = LearningPlanner.instance;
  final ConversationEvaluator _evaluator = ConversationEvaluator.instance;
  final TeacherAIService _aiService = TeacherAIService.instance;

  bool _isLearningMode = false;
  StudyMaterial? _currentMaterial;
  int _currentSentenceIndex = 0;

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
    await _processor.init();
    await _hearing.init();
    await _tts.init();
    await _aiService.initialize();

    _hearing.onText.listen((text) {
       if (_orbState == 'listening') {
         // 실시간 피드백 로직
       }
    });

    _addMessage(Lang.t('system_online'), "luna");
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pageController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _hearing.stopListening();
    _tts.stop();
    super.dispose();
  }

  // --- [Logic Methods] ---

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 150,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(String text, String sender, {Widget? customWidget}) {
    setState(() {
      chatHistory.add({
        'text': text, 
        'sender': sender, 
        'time': "${DateTime.now().hour}:${DateTime.now().minute}",
        'widget': customWidget 
      });
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _speakMultiLang(String text, String langCode) async {
    await _tts.speak(text); 
  }

  void _toggleMic() {
    if (_orbState == 'listening') {
      _hearing.stopListening();
      setState(() => _orbState = 'idle');
    } else {
      setState(() => _orbState = 'listening');
      _hearing.startListening();
      
      late StreamSubscription sub;
      sub = _hearing.onText.listen((text) {
        if (text.isNotEmpty) {
           _handleUserInput(text);
           setState(() => _orbState = 'idle');
           _hearing.stopListening();
           sub.cancel(); 
        }
      });
    }
  }

  Future<void> _handleUserInput(String input) async {
    if (input.trim().isEmpty) return;
    _addMessage(input, 'me'); 

    // 1. 학습 모드
    if (_isLearningMode) {
      _processLearningStep(input);
      return;
    }

    // 2. 학습 시작 명령
    if (input.contains("공부") || input.contains("학습") || input.contains("영어")) {
       _startLearningSession();
       return;
    }

    // 3. 도구 실행 명령
    String? actionId;
    if (input.contains("타이머")) {
      actionId = "tool_timer";
    } else if (input.contains("녹음")) {
      actionId = "tool_record";
    } else if (input.contains("계산기")) {
      actionId = "tool_calc";
    } else if (input.contains("메모")) {
      actionId = "quick_text_memo";
    }

    if (actionId != null) {
      setState(() => _orbState = 'speaking');
      await _tts.speak("알겠습니다.");
      if (mounted) {
        ActionHandler.execute(context, actionId, input); 
      }
      Future.delayed(const Duration(seconds: 1), () => setState(() => _orbState = 'idle'));
      return;
    }

    // 4. 하이브리드 프로세서 처리
    setState(() => _orbState = 'thinking');
    
    try {
      String response = await _processor.processInput(input);
      
      if (mounted) {
        _addMessage(response, 'luna');
        await _tts.speak(response); 
        setState(() => _orbState = 'idle');
      }
    } catch (e) {
      debugPrint("Processor Error: $e");
      if (mounted) {
        _addMessage("죄송해요, 연결 상태를 확인해주세요.", 'luna');
        setState(() => _orbState = 'idle');
      }
    }
  }

  // --- [Learning Logic] ---
  Future<void> _startLearningSession() async {
    setState(() => _isLearningMode = true);
    _addMessage("오늘의 맞춤형 학습 루틴을 시작합니다.", 'luna');
    final plan = await _planner.generateDailyPlan(count: 1); 
    _currentMaterial = plan.first;
    _currentSentenceIndex = 0;
    
    if (_currentMaterial != null) {
      _addMessage(
        "Mission: ${_currentMaterial!.title}",
        'luna',
        customWidget: _buildLearningCard(_currentMaterial!),
      );
    }
  }

  void _processLearningStep(String input) {
    if (_currentMaterial != null) {
      final sentences = _currentMaterial!.contentOriginal.split("\n");
      if (_currentSentenceIndex < sentences.length) {
        final targetPart = sentences[_currentSentenceIndex].split(":")[1].trim();
        final result = _evaluator.evaluate(input, targetPart);
        
        _addMessage(
          "Analysis", 
          'luna',
          customWidget: _buildFeedbackCard(result, targetPart)
        );

        if (result['score'] >= 80) _speakMultiLang("Great!", "en-US");

        _aiService.updateProgress(_currentMaterial!.id, (_currentSentenceIndex + 1) / sentences.length);
        _currentSentenceIndex++;

        if (_currentSentenceIndex >= sentences.length) {
           setState(() => _isLearningMode = false);
           _addMessage("Session Complete! 수고하셨어요.", 'luna');
           _speakMultiLang("학습이 완료되었습니다.", "ko-KR");
        }
      }
    }
  }

  // --- [UI Building Blocks] ---

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
          Positioned(
            top: orbTop, left: 0, right: 0,
            child: Center(child: Transform.scale(scale: orbScale, child: _buildLivingOrb())),
          ),
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              children: [
                _buildChatPage(screenSize), 
                _buildDashboardPage(screenSize), 
              ],
            ),
          ),
          Positioned(
            top: statusBarHeight + 10,
            left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Column(
                  children: [
                    Text(Lang.t('luna'), style: const TextStyle(color: Colors.white24, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold)),
                    if (_orbState == 'listening')
                      Text("● REC", style: const TextStyle(color: LuenColors.micRed, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.school, color: Colors.tealAccent),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherScreen())),
                ),
              ],
            ),
          ),
          if (!_isKeyboardVisible) Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomDock()),
          if (_isKeyboardVisible) Positioned(bottom: 0, left: 0, right: 0, child: _buildInputArea()),
        ],
      ),
    );
  }

  Widget _buildLivingOrb() {
    Color coreColor = Colors.blue;
    if (_orbState == 'listening') coreColor = Colors.red;
    if (_orbState == 'speaking') coreColor = Colors.cyan;
    if (_orbState == 'thinking') coreColor = Colors.purple;
    if (_isLearningMode) coreColor = Colors.tealAccent; 

    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.8), coreColor.withValues(alpha: 0.6), Colors.transparent],
              stops: const [0.0, 0.4, 1.0],
            ),
            boxShadow: [BoxShadow(color: coreColor.withValues(alpha: 0.3), blurRadius: 40 + (20 * _breatheController.value))]
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
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
              ),
              if (msg['widget'] != null) ...[msg['widget'], const SizedBox(height: 10)],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardPage(Size size) {
    final learningHistory = _aiService.getLearningHistory();
    
    return Container(
      padding: EdgeInsets.only(top: size.height * 0.35, left: 20, right: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SITUATION ROOM",
            style: TextStyle(color: Colors.tealAccent, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          
          _buildInfoCard(
            title: "System Status",
            icon: Icons.monitor_heart_outlined,
            content: "• Luna AI: Online\n• Friend Mode: Active (Level 10)\n• Voice Engine: Ready",
          ),
          const SizedBox(height: 15),

          _buildInfoCard(
            title: "Learning Progress",
            icon: Icons.school_outlined,
            content: learningHistory.isEmpty 
              ? "No recent activity.\nSay 'Start Learning' to begin."
              : "• Sessions: ${learningHistory.length}\n• Current Level: Intermediate",
          ),
          const SizedBox(height: 15),

          _buildInfoCard(
            title: "Daily Brief",
            icon: Icons.summarize_outlined,
            content: "• Schedule: No pending items.\n• Condition: Good.\n• Suggestion: Try 'Free Talk' mode.",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLearningCard(StudyMaterial material) {
    return Container(
      width: 280, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.tealAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(material.title, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(material.contentOriginal, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> result, String target) {
    return Container(
      width: 280, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900], 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(result['feedback'], style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildBottomDock() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 100, color: Colors.black.withValues(alpha: 0.5),
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
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white70), 
                onPressed: () { 
                   _addMessage("카메라 분석 기능은 준비 중입니다.", 'luna');
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: const Color(0xFF0B0B0E), padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController, autofocus: true, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "대화 또는 명령...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
              ),
              onSubmitted: (t) { _handleUserInput(t); _textController.clear(); setState(() => _isKeyboardVisible = false); },
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false)),
        ],
      ),
    );
  }
}