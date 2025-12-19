import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../luen_colors.dart';
import '../services/lang.dart';
import '../util/action_handler.dart'; 
import '../data/menu_data.dart';

// [Gen-4] Teacher 모듈 & 엔진 연동
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
  // --- [컨트롤러] ---
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _breatheController;

  // --- [음성 엔진] ---
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isSpeechAvailable = false;
  
  final String _currentLocaleId = "ko-KR"; 

  // --- [상태 변수] ---
  String _orbState = 'idle'; 
  bool _isKeyboardVisible = false;
  double _currentPageValue = 0.0;
  List<Map<String, dynamic>> chatHistory = [];

  // --- [학습 엔진] ---
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
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await _aiService.initialize();

    _isSpeechAvailable = await _speech.initialize(onError: (e) => debugPrint("STT Error: $e"));
    await _flutterTts.setLanguage(_currentLocaleId);
    
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
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.speak(text);
    await _flutterTts.setLanguage(_currentLocaleId);
  }

  void _toggleMic() async {
    if (!_isSpeechAvailable) return;

    if (_speech.isListening) {
      _speech.stop();
      setState(() => _orbState = 'idle');
    } else {
      setState(() => _orbState = 'listening');
      String locale = _isLearningMode ? "en-US" : "ko-KR";
      
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            _handleUserInput(val.recognizedWords);
            setState(() => _orbState = 'idle');
          }
        },
        localeId: locale,
      );
    }
  }

  void _handleUserInput(String input) {
    if (input.trim().isEmpty) return;
    _addMessage(input, 'me'); 

    if (_isLearningMode) {
      _processLearningStep(input);
      return;
    }

    if (input.contains("주문") || input.contains("카페") || input.contains("여행")) {
       _startContextualLearning(input);
       return;
    }

    if (input.contains("공부") || input.contains("학습") || input.contains("영어")) {
       _startLearningSession();
       return;
    }

    String? actionId;
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
      _speakMultiLang("확인했습니다.", "ko-KR");
      ActionHandler.execute(context, actionId, input);
      Future.delayed(const Duration(seconds: 2), () => setState(() => _orbState = 'idle'));
      return;
    }

    setState(() => _orbState = 'thinking');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        String reply = "제가 도울 수 있는 일을 말씀해주세요. (예: '카페 회화 연습하자', '영어 공부 시작해')";
        _addMessage(reply, 'luna');
        _speakMultiLang(reply, "ko-KR");
        setState(() => _orbState = 'idle');
      }
    });
  }

  // [Gen-4 Ultimate] 카메라 상황 인식 및 즉시 학습
  Future<void> _analyzeSceneAndLearn() async {
    setState(() => _orbState = 'thinking');
    _addMessage("📸 시각 정보를 분석하고 있습니다...", 'luna');
    await _speakMultiLang("잠시만요, 지금 계신 곳을 보고 있어요.", "ko-KR");

    // 1. Vision AI 분석 (Teacher Service 호출)
    String situation = await _aiService.analyzeImageAndGetTopic("dummy_path.jpg");
    
    // 2. 결과 안내
    setState(() => _orbState = 'idle');
    _addMessage("아하! 지금 '$situation' 상황이시군요.", 'luna');
    await _speakMultiLang("지금 상황에 딱 맞는 회화를 알려드릴게요.", "ko-KR");

    // 3. 즉시 맥락 학습 실행
    await _startContextualLearning(situation);
  }

  Future<void> _startContextualLearning(String situation) async {
    setState(() => _isLearningMode = true);
    _addMessage("'$situation' 상황에 맞는 실전 회화를 준비했습니다.", 'luna');
    
    final plan = await _planner.generateContextualPlan(situation);
    _currentMaterial = plan.first;
    _currentSentenceIndex = 0;
    
    if (_currentMaterial != null) {
      _addMessage(
        "Situation: ${_currentMaterial!.title}",
        'luna',
        customWidget: Column(
          children: [
            _buildARVRTutorPlaceholder(), 
            const SizedBox(height: 10),
            _buildLearningCard(_currentMaterial!),
          ],
        ),
      );
    }
  }

  Future<void> _startLearningSession() async {
    setState(() => _isLearningMode = true);
    
    final weakItem = await _planner.predictWeakPoints();
    if (weakItem != null) {
       _addMessage("잠깐! 지난번에 어려워했던 내용을 먼저 복습할까요?", 'luna');
       _currentMaterial = weakItem;
    } else {
       _addMessage("오늘의 맞춤형 학습 루틴을 시작합니다.", 'luna');
       final plan = await _planner.generateDailyPlan(count: 1); 
       _currentMaterial = plan.first;
    }

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
          "AI Analysis Result", 
          'luna',
          customWidget: _buildFeedbackCard(result, targetPart)
        );

        if(result['score'] >= 80) {
          _speakMultiLang("Great job! 아주 잘했어요!", "ko-KR");
        } else {
          _speakMultiLang("Try again. 다시 한번 해보세요.", "ko-KR");
        }

        _aiService.updateProgress(_currentMaterial!.id, (_currentSentenceIndex + 1) / sentences.length);
        _currentSentenceIndex++;

        if (_currentSentenceIndex >= sentences.length) {
           setState(() => _isLearningMode = false);
           _addMessage("🎉 오늘의 세션이 종료되었습니다. 수고하셨어요!", 'luna');
           _speakMultiLang("학습이 완료되었습니다.", "ko-KR");
        }
      }
    }
  }

  // --- [UI 위젯 빌더] ---

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
                      Text("● ${Lang.t('rec')}", style: const TextStyle(color: LuenColors.micRed, fontSize: 10, letterSpacing: 1)),
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

  Widget _buildARVRTutorPlaceholder() {
    return Container(
      width: 250, height: 200, 
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3), width: 1.0),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face, color: Colors.tealAccent, size: 40),
            SizedBox(height: 8),
            Text("AI Tutor Avatar\n(Interactive Mode)", style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCard(StudyMaterial material) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🔥 Mission: ${material.title}", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          Text(material.contentOriginal, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: () => _speakMultiLang(material.contentOriginal, "en-US"), 
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> result, String target) {
    final int score = result['score'];
    final List<String> weakWords = result['weak_words'] ?? [];
    
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: score >= 80 ? Colors.greenAccent : Colors.orangeAccent, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Score: $score", style: TextStyle(color: score >= 80 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
              Icon(score >= 80 ? Icons.check_circle : Icons.warning_amber_rounded, color: score >= 80 ? Colors.greenAccent : Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 8),
          Text(result['feedback'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (weakWords.isNotEmpty) ...[
            const Divider(color: Colors.grey),
            const Text("Weak Points:", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            Wrap(
              spacing: 4,
              children: weakWords.map((w) => Chip(
                label: Text(w, style: const TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: Colors.red.withValues(alpha: 0.3),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.yellowAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(result['intonation_tip'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardPage(Size size) {
    final items = LunaMenuData.getFunctions("비서") + LunaMenuData.getFunctions("도구");
    return GridView.builder(
      padding: EdgeInsets.only(top: size.height * 0.25, left: 20, right: 20, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => ActionHandler.execute(context, item.actionId, item.title),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: Colors.blueAccent, size: 30), const SizedBox(height: 8), Text(item.title, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center)]),
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
          height: 100, color: Colors.black.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.keyboard, color: Colors.white70), onPressed: () => setState(() => _isKeyboardVisible = true)),
              GestureDetector(
                onTap: _toggleMic,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: _isLearningMode ? Colors.teal : (_orbState == 'listening' ? Colors.red : Colors.blue),
                  child: Icon(_isLearningMode ? Icons.school : Icons.mic, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white70), 
                onPressed: () => _analyzeSceneAndLearn(),
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
              decoration: InputDecoration(hintText: _isLearningMode ? "답변을 입력하세요..." : "명령 입력...", hintStyle: const TextStyle(color: Colors.white38), fillColor: Colors.white.withValues(alpha: 0.1), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
              onSubmitted: (t) { _handleUserInput(t); _textController.clear(); setState(() => _isKeyboardVisible = false); },
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false)),
        ],
      ),
    );
  }
}