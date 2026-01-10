import 'package:flutter/material.dart';
import '../../modules/system_module.dart';
import '../../modules/teacher/ui/teacher_screen.dart';
import '../../modules/friend/ui/friend_screen.dart';
import '../../widgets/luen_colors.dart';

// [혁신적 해결 포인트] 
// 기존: import '../../modules/assistant/ui/assistant_screen.dart'; (X - 옛날 파일)
// 변경: 아래 파일로 강제 연결 (O - 방금 고친 파일)
import '../../modules/assistant/assist_module.dart'; 

class MenuTab extends StatefulWidget {
  final SystemModule systemModule;

  const MenuTab({super.key, required this.systemModule});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [헤더]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("LUNA OS", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 30, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0
                    )
                  ),
                  
                  // [배터리] 회색
                  Container(
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
                ],
              ),
              
              const SizedBox(height: 10),
              Divider(color: LuenColors.neonPoint.withValues(alpha: 0.2), thickness: 1),
              
              const SizedBox(height: 50),

              Expanded(
                child: ListView(
                  children: [
                    // 1. [HERO] 비서 모드
                    _buildHeroCommand(
                      context,
                      index: "01",
                      title: "AI SECRETARY", 
                      subtitle: "Schedule & Briefing",
                      // [클릭 시 이동] 이제 assist_module.dart의 새 화면으로 이동합니다.
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AssistantScreen())),
                    ),

                    const SizedBox(height: 40),

                    // 2. [NORMAL] 튜터 모드
                    _buildNeonCommand(
                      context, 
                      index: "02",
                      title: "AI TUTOR", 
                      subtitle: "Deep Learning Module",
                      icon: Icons.school_outlined, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherScreen())),
                    ),

                    const SizedBox(height: 30),

                    // 3. [NORMAL] 친구 모드
                    _buildNeonCommand(
                      context, 
                      index: "03",
                      title: "AI FRIEND", 
                      subtitle: "Conversation Core",
                      icon: Icons.favorite_border, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [위젯] 히어로 버튼 (네온 테두리 + 글로우)
  Widget _buildHeroCommand(BuildContext context, {required String index, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              border: Border.all(
                color: LuenColors.neonPoint.withValues(alpha: _pulseController.value * 0.6 + 0.3), 
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: LuenColors.neonPoint.withValues(alpha: _pulseController.value * 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              children: [
                Text(index, style: const TextStyle(color: LuenColors.neonPoint, fontSize: 16, fontFamily: "Courier", fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: "Courier")),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: LuenColors.neonPoint.withValues(alpha: 0.8), size: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // [위젯] 일반 버튼 (약한 네온)
  Widget _buildNeonCommand(BuildContext context, {required String index, required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: LuenColors.neonPoint.withValues(alpha: 0.3), width: 1.0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(index, style: const TextStyle(color: Colors.white30, fontSize: 14, fontFamily: "Courier")),
            const SizedBox(width: 25),
            Icon(icon, color: LuenColors.neonPoint, size: 22),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 11, fontFamily: "Courier")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}