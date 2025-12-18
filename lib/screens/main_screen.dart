import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../luen_colors.dart';
import '../services/luna_brain.dart';
import '../services/lang.dart';

// [New] 선물 게이지 및 서비스 연결
import '../widgets/luna_gift_bar.dart';
import '../services/luna_integrated_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final ImagePicker _picker = ImagePicker();

  String _currentFocus = 'assistant';
  String _orbState = 'idle';
  bool _isKeyboardVisible = false;
  double _currentPageValue = 0.0;
  bool _isSpeechAvailable = false;
  bool _isHeadsetConnected = false;
  bool _isAlwaysListening = false;

  Timer? _lifeCycleTimer;
  DateTime _lastInteractionTime = DateTime.now(); 
  List<Map<String, String>> chatHistory = [];
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initSystem();
    _startLifeCycle();

    _breatheController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pageController.addListener(() {
      setState(() { _currentPageValue = _pageController.page ?? 0.0; });
    });
  }

  void _startLifeCycle() {
    _lifeCycleTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_orbState != 'idle') return;

      final now = DateTime.now();
      final silenceDuration = now.difference(_lastInteractionTime).inSeconds;
      
      if (_isHeadsetConnected && silenceDuration > 30 && silenceDuration < 40) {
        _triggerProactiveAction("심심하신가요? 제가 재미있는 이야기라도 해드릴까요?");
      }
      if (now.minute == 0 && now.second <= 10) {
        if (now.hour == 12) { _triggerProactiveAction("점심 시간이에요! 맛있는 거 드세요."); }
        if (now.hour == 23) { _triggerProactiveAction("밤이 늦었어요. 오늘 하루도 고생 많으셨어요."); }
      }
      if (silenceDuration > 3600 && silenceDuration < 3615) {
        _triggerProactiveAction("저 여기 있어요. 필요하면 언제든 불러주세요.");
      }
    });
  }

  void _triggerProactiveAction(String message) {
    if (_orbState != 'idle') return;
    _addMessage(message, 'luna');
    setState(() => _orbState = 'speaking');
    _flutterTts.speak(message);
    _lastInteractionTime = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _initSystem() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    session.devicesChangedEventStream.listen((event) => _checkAudioOutput());
    _checkAudioOutput();

    _isSpeechAvailable = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isAlwaysListening && _orbState != 'speaking') {
           _startListening(); 
        }
      },
      onError: (e) { if (_isAlwaysListening) { _startListening(); } },
    );
    
    await _flutterTts.setLanguage(Lang.ttsCode);
    _flutterTts.setCompletionHandler(() {
      setState(() => _orbState = 'idle');
      if (_isAlwaysListening) { _startListening(); }
    });
    _loadHistory();
  }

  Future<void> _checkAudioOutput() async {
    final session = await AudioSession.instance;
    final devices = await session.getDevices();
    bool headsetFound = devices.any((d) => 
      d.type == AudioDeviceType.wiredHeadset || 
      d.type == AudioDeviceType.bluetoothSco || 
      d.type == AudioDeviceType.bluetoothA2dp
    );

    if (mounted) {
      setState(() {
        _isHeadsetConnected = headsetFound;
        _isAlwaysListening = headsetFound; 
      });
      if (_isHeadsetConnected) { _startListening(); }
      else { _speech.stop(); }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _lifeCycleTimer?.cancel();
    _breatheController.dispose();
    _pageController.dispose();
    _textController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('luen_history');
    if (saved != null) {
      setState(() { chatHistory = saved.map((e) => Map<String, String>.from(jsonDecode(e))).toList(); });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      _addMessage(Lang.t('system_online'), "luna");
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saveList = chatHistory.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('luen_history', saveList);
  }

  void _addMessage(String text, String sender) {
    setState(() { 
      chatHistory.add({'text': text, 'sender': sender, 'time': _getCurrentTime()}); 
    });
    _lastInteractionTime = DateTime.now();
    _saveHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _startListening() async {
    if (!_isSpeechAvailable || _speech.isListening || _orbState == 'speaking') return;

    setState(() => _orbState = 'listening');
    _speech.listen(
      onResult: (val) {
        if (_isHeadsetConnected && val.recognizedWords.isNotEmpty) { _flutterTts.stop(); }
        if (val.finalResult) { _handleUserInput(val.recognizedWords); }
      },
      localeId: Lang.sttCode, 
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(partialResults: true),
    );
  }

  void _toggleMic() {
    setState(() => _isAlwaysListening = !_isAlwaysListening);
    if (_isAlwaysListening) { _startListening(); }
    else {
      _speech.stop();
      setState(() => _orbState = 'idle');
    }
  }

  Future<void> _activateVision() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
        _handleAIResponse("Camera permission needed.");
        return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _addMessage(Lang.t('image_uploaded'), "me");
      setState(() => _orbState = 'thinking');
      Future.delayed(const Duration(seconds: 1), () {
        _handleAIResponse("Wow, nice view!"); 
      });
    }
  }

  void _handleUserInput(String input) {
    if (input.trim().isEmpty) return;
    if (!_isHeadsetConnected) { _speech.stop(); }
    _addMessage(input, 'me'); 
    setState(() => _orbState = 'thinking');
    _fetchAIResponse(input);
  }

  Future<void> _fetchAIResponse(String input) async {
    try {
      String reply = await LunaBrain().getResponse(input);
      _handleAIResponse(reply);
    } catch (e) {
      _handleAIResponse("Connection Error.");
    }
  }

  void _handleAIResponse(String responseText) {
    setState(() => _orbState = 'speaking');
    _addMessage(responseText, 'luna');
    _flutterTts.speak(responseText);
  }
  
  void _changeFocus(String focus) {
    setState(() => _currentFocus = focus);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double orbBaseTop = screenSize.height * 0.18;
    final double orbDashTop = screenSize.height * 0.08;
    
    // 페이지 이동에 따른 오브 위치 계산
    double orbTop = orbBaseTop - (_currentPageValue * (orbBaseTop - orbDashTop));
    double orbScale = 1.0 - (_currentPageValue * 0.5);

    // [중요] 상태바 높이 (배터리 표시줄 높이)
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
          
          // 2. 루나 오브 (Orb)
          Positioned(
            top: orbTop, left: 0, right: 0,
            child: Center(
              child: Transform.scale(scale: orbScale, child: _buildLivingOrb()),
            ),
          ),
          
          // 3. 페이지 컨텐츠
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              children: [
                _buildChatPage(screenSize),
                _buildDashboardPage(screenSize),
              ],
            ),
          ),

          // -------------------------------------------------------------
          // 4. [New] 선물 게이지 (상태바 바로 아래에 쌍둥이처럼 배치)
          // -------------------------------------------------------------
          Positioned(
            top: statusBarHeight, // 핸드폰 배터리 표시 바로 밑
            left: 0,
            right: 0,
            child: LunaGiftBar(
              systemModule: LunaIntegratedService().systemModule,
            ),
          ),
          
          // 5. 상단 텍스트 정보 (LUNA / REC)
          // 게이지와 겹치지 않게 위치를 살짝 아래로 조정 (statusBarHeight + 60)
          Positioned(
            top: statusBarHeight + 60,
            left: 0, right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(Lang.t('luna'), style: const TextStyle(color: Colors.white24, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold)),
                  if (_orbState == 'listening')
                    Text(_isHeadsetConnected ? "🎧 ${Lang.t('rec')} (Auto)" : "● ${Lang.t('rec')}", 
                      style: const TextStyle(color: LuenColors.micRed, fontSize: 10, letterSpacing: 1)),
                ],
              ),
            ),
          ),

          // 6. 하단 독
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomDock(screenSize)),
          
          // 7. 키보드 영역
          if (_isKeyboardVisible) Positioned(bottom: 0, left: 0, right: 0, child: _buildInputArea()),
        ],
      ),
    );
  }

  Widget _buildLivingOrb() {
    Color coreColor;
    switch (_orbState) {
      case 'listening': coreColor = LuenColors.micRed; break;
      case 'speaking': coreColor = Colors.cyanAccent; break;
      case 'thinking': coreColor = Colors.deepPurpleAccent; break;
      default: coreColor = _currentFocus == 'friends' ? LuenColors.friendPink : LuenColors.primaryBlue;
    }
    return GestureDetector(
      onTap: () { _flutterTts.stop(); _startListening(); },
      child: AnimatedBuilder(animation: _breatheController, builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500), 
          width: 200, height: 200, 
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.8), coreColor.withValues(alpha: 0.6), coreColor.withValues(alpha: 0.1), Colors.transparent], 
              stops: const [0.0, 0.4, 0.7, 1.0]
            ), 
            boxShadow: [BoxShadow(color: coreColor.withValues(alpha: 0.5 * _breatheController.value + 0.2), blurRadius: 60 + (30 * _breatheController.value), spreadRadius: 10)]
          ), 
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5))))
        );
      }),
    );
  }

  Widget _buildChatPage(Size size) {
     return ListView.builder(
       controller: _scrollController, 
       padding: EdgeInsets.fromLTRB(20, size.height * 0.4, 20, 120), 
       itemCount: chatHistory.length, 
       itemBuilder: (context, index) { 
         final msg = chatHistory[index]; 
         bool isMe = msg['sender'] == 'me'; 
         return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(onTap: () { if (!isMe) _flutterTts.speak(msg['text']!); }, onLongPress: () { Clipboard.setData(ClipboardData(text: msg['text']!)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied"), duration: Duration(milliseconds: 500))); }, child: Container(margin: const EdgeInsets.only(bottom: 20), constraints: const BoxConstraints(maxWidth: 280), color: Colors.transparent, child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [Text(msg['text']!, style: TextStyle(color: isMe ? LuenColors.textUser : LuenColors.textLuna, fontSize: 16, height: 1.5)), const SizedBox(height: 5), Text(msg['time']!, style: const TextStyle(color: Colors.white24, fontSize: 10))])))); 
       }
     );
  }

  Widget _buildDashboardPage(Size size) { 
    return Container(padding: EdgeInsets.fromLTRB(25, size.height * 0.18, 25, 120), child: Column(children: [Row(children: [_buildFocusChip('assistant', '👔', Lang.t('mode_assistant')), const SizedBox(width: 10), _buildFocusChip('learning', '🎓', Lang.t('mode_learning')), const SizedBox(width: 10), _buildFocusChip('friends', '💖', Lang.t('mode_friends'))]), const SizedBox(height: 30), Expanded(child: _buildAdaptiveContent())])); 
  }

  Widget _buildFocusChip(String id, String icon, String label) { 
    bool isActive = _currentFocus == id; 
    Color activeColor = id == 'friends' ? LuenColors.friendPink : LuenColors.primaryBlue; 
    return Expanded(child: GestureDetector(onTap: () => _changeFocus(id), child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 90, decoration: BoxDecoration(color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(height: 8), Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))])))); 
  }

  Widget _buildAdaptiveContent() { 
    if (_currentFocus == 'friends') { 
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(Lang.t('my_companion')), _buildInfoRow(Lang.t('luna'), "Headset Check", _isHeadsetConnected ? "Connected" : "None", LuenColors.friendPink), const SizedBox(height: 20), _buildHeader(Lang.t('together')), Row(children: [Expanded(child: _buildActionBtn("🌙 ${Lang.t('deep_talk')}", () => _handleUserInput("위로가 필요해"))), const SizedBox(width: 10), Expanded(child: _buildActionBtn("💌 ${Lang.t('emotion')}", () => _handleUserInput("기분 분석해줘")))])]); 
    } else if (_currentFocus == 'learning') { 
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(Lang.t('progress')), _buildInfoRow(Lang.t('daily_goal'), "Context Learning", "Active", LuenColors.primaryBlue), const SizedBox(height: 20), _buildHeader("ACTIONS"), Row(children: [Expanded(child: _buildActionBtn("📝 ${Lang.t('review')}", () => _handleUserInput("복습 시작"))), const SizedBox(width: 10), Expanded(child: _buildActionBtn("🗣️ ${Lang.t('speaking')}", () => _handleUserInput("회화 연습")))])]); 
    } else { 
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeader(Lang.t('priority')), Row(children: [Expanded(child: _buildActionBtn("📅 ${Lang.t('schedule')}", () => _handleUserInput("일정 확인"))), const SizedBox(width: 10), Expanded(child: _buildActionBtn("✉️ ${Lang.t('email')}", () => _handleUserInput("이메일 확인")))]), const SizedBox(height: 20), _buildHeader(Lang.t('logs')), _buildInfoRow(Lang.t('contract_sent'), "System Optimal", "✔", LuenColors.primaryBlue)]); 
    } 
  }

  Widget _buildHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)));
  Widget _buildInfoRow(String title, String sub, String stat, Color color) { return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(height: 4), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12))]), Text(stat, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])); }
  Widget _buildActionBtn(String title, VoidCallback onTap) { return GestureDetector(onTap: onTap, child: Container(height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)))); }
  
  Widget _buildBottomDock(Size size) { 
    if (_isKeyboardVisible) return const SizedBox.shrink(); 
    return ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(height: 100 + MediaQuery.of(context).padding.bottom, padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), decoration: BoxDecoration(color: const Color(0xFF141419).withValues(alpha: 0.85), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white38), onPressed: () => setState(() => _isKeyboardVisible = true)), GestureDetector(onTap: _toggleMic, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF15151A), Colors.black]), border: Border.all(color: _isAlwaysListening ? LuenColors.micRed : const Color(0xFF64B5F6).withValues(alpha: 0.3), width: 1.5), boxShadow: _isAlwaysListening ? [const BoxShadow(color: LuenColors.micRed, blurRadius: 20)] : []), child: Icon(Icons.mic, color: _isAlwaysListening ? LuenColors.micRed : LuenColors.primaryBlue, size: 30))), IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.white38), onPressed: _activateVision)])))); 
  }

  Widget _buildInputArea() { 
    return Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), color: const Color(0xFF0B0B0E), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), child: Row(children: [Expanded(child: TextField(controller: _textController, autofocus: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: Lang.t('hint'), hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withValues(alpha: 0.08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20)), onSubmitted: (_) => _handleUserInput(_textController.text))), IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _isKeyboardVisible = false))]))); 
  }
}