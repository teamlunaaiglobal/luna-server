import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  final String orbState; 
  final List<Map<String, dynamic>> chatHistory;
  final VoidCallback onMicTap;
  final VoidCallback onCameraTap;
  
  // 👉 [추가] 키보드 버튼 눌렀을 때 신호 받기
  final VoidCallback onKeyboardTap; 

  final AnimationController breatheController;
  final ScrollController scrollController;

  const HomeTab({
    super.key,
    required this.orbState,
    required this.chatHistory,
    required this.onMicTap,
    required this.onCameraTap,
    required this.onKeyboardTap, // 필수 항목으로 추가
    required this.breatheController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 오브
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0, right: 0,
          child: Center(child: _buildLivingOrb()),
        ),

        // 2. 채팅창
        Positioned.fill(
          top: MediaQuery.of(context).size.height * 0.4,
          bottom: 100,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: chatHistory.length,
            itemBuilder: (context, index) {
              final msg = chatHistory[index];
              final isMe = msg['sender'] == 'me';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? const Color(0xFF4A90E2).withValues(alpha: 0.3) 
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(msg['text'], style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
        ),

        // 3. 하단 버튼들 (키보드 부활!)
        Positioned(
          bottom: 30, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1) 키보드 버튼 (부활!)
              IconButton(
                icon: const Icon(Icons.keyboard, color: Colors.white54, size: 30),
                onPressed: onKeyboardTap,
              ),

              // 2) 마이크 버튼
              GestureDetector(
                onTap: onMicTap,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: orbState == 'listening' ? const Color(0xFFFF6B6B) : const Color(0xFF4A90E2),
                  child: const Icon(Icons.mic, color: Colors.white, size: 30),
                ),
              ),

              // 3) 카메라 버튼
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white54, size: 30),
                onPressed: onCameraTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivingOrb() {
    Color coreColor = const Color(0xFF4A90E2); 
    if (orbState == 'listening') coreColor = const Color(0xFFFF6B6B);
    if (orbState == 'thinking') coreColor = const Color(0xFFBA68C8);
    if (orbState == 'speaking') coreColor = const Color(0xFF4FC3F7);

    return AnimatedBuilder(
      animation: breatheController,
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
                blurRadius: 40 + (20 * breatheController.value),
                spreadRadius: 5 * breatheController.value,
              )
            ],
          ),
        );
      },
    );
  }
}