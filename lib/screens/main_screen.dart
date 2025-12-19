// ... (기존 코드)

  // [Gen-4 Ultimate] 카메라로 상황 인식 후 학습 시작
  Future<void> _analyzeSceneAndLearn() async {
    setState(() => _orbState = 'thinking');
    _addMessage("눈앞의 상황을 분석하고 있습니다...", 'luna');
    _flutterTts.speak("잠시만요, 지금 계신 곳을 보고 있어요.");

    // 1. 카메라 촬영 (시뮬레이션) -> 실제로는 image_picker 패키지로 파일 경로를 받음
    String mockImagePath = "path/to/camera/image.jpg";
    
    // 2. Vision AI 분석
    String situation = await _aiService.analyzeImageAndGetTopic(mockImagePath);
    
    // 3. 분석 결과 안내
    setState(() => _orbState = 'idle');
    _addMessage("아하! 지금 '$situation' 상황이시군요.", 'luna');
    _flutterTts.speak("지금 상황에 딱 맞는 회화를 알려드릴게요.");

    // 4. 즉시 맥락 학습 실행 (기존 메서드 재사용)
    _startContextualLearning(situation);
  }

// ... (기존 코드)

  // 하단 독의 카메라 버튼 수정
  Widget _buildBottomDock() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          // ... (스타일 유지)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.keyboard, color: Colors.white70), onPressed: () => setState(() => _isKeyboardVisible = true)),
              GestureDetector(
                onTap: _toggleMic,
                child: CircleAvatar(/*...*/),
              ),
              // [수정] 카메라 버튼을 누르면 Vision Learning 시작
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white70), 
                onPressed: () {
                   // 기존 도구 실행 대신, Vision 학습 실행
                   _analyzeSceneAndLearn(); 
                }
              ),
            ],
          ),
        ),
      ),
    );
  }