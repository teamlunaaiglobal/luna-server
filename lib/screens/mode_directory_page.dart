import 'package:flutter/material.dart';
import 'mode_detail_page.dart'; // 상세 페이지 연결

class ModeDirectoryPage extends StatelessWidget {
  const ModeDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("LUNA DIRECTORY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Root Directory",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            const Text(
              "루나의 3대 핵심 영역입니다.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 1. 친구 모드
            _buildRootCard(
              context,
              title: "Friend Mode",
              subtitle: "감성 대화 및 추억",
              icon: Icons.favorite,
              color: Colors.pinkAccent,
              notificationCount: 0, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FriendSubPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. 비서 모드
            _buildRootCard(
              context,
              title: "Assistant Mode",
              subtitle: "8가지 업무 관리 도구",
              icon: Icons.business_center,
              color: Colors.blueAccent,
              notificationCount: 5, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssistantSubPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // 3. 학습 모드
            _buildRootCard(
              context,
              title: "Tutor Mode",
              subtitle: "퀴즈 및 지식 학습",
              icon: Icons.school,
              color: Colors.amber[800]!,
              notificationCount: 2, 
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorSubPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int notificationCount,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 16, top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text("$notificationCount", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

// 서브 페이지들 (친구/비서/학습)
class FriendSubPage extends StatelessWidget {
  const FriendSubPage({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildGenericSubPage(context, "Friend Space", [
      {'icon': Icons.book, 'title': '감정 일기', 'desc': '오늘의 기록', 'alert': 1},
      {'icon': Icons.photo_album, 'title': '추억 보관함', 'desc': '공유된 사진', 'alert': 0},
    ]);
  }
}

class AssistantSubPage extends StatelessWidget {
  const AssistantSubPage({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildGenericSubPage(context, "Assistant Tools", [
      {'icon': Icons.mic, 'title': '캡처 & 기록', 'desc': '순간 기록', 'alert': 0},
      {'icon': Icons.business_center, 'title': '회의 & 업무', 'desc': '업무 핵심', 'alert': 3},
      {'icon': Icons.folder, 'title': '문서 & 파일', 'desc': '자료 정리', 'alert': 0},
      {'icon': Icons.calendar_today, 'title': '일정 & 할일', 'desc': '시간 관리', 'alert': 2},
      {'icon': Icons.mail, 'title': '메일 & 톡', 'desc': '커뮤니케이션', 'alert': 0},
      {'icon': Icons.search, 'title': '리서치', 'desc': '지식 탐색', 'alert': 0},
      {'icon': Icons.person, 'title': '개인 관리', 'desc': '회고/습관', 'alert': 0},
      {'icon': Icons.share, 'title': '전달 & 공유', 'desc': '결과 공유', 'alert': 0},
    ]);
  }
}

class TutorSubPage extends StatelessWidget {
  const TutorSubPage({super.key});
  @override
  Widget build(BuildContext context) {
    return _buildGenericSubPage(context, "Tutor Class", [
      {'icon': Icons.quiz, 'title': '오늘의 퀴즈', 'desc': '복습 시간', 'alert': 3},
      {'icon': Icons.note_alt, 'title': '오답 노트', 'desc': '틀린 문제', 'alert': 0},
    ]);
  }
}

Widget _buildGenericSubPage(BuildContext context, String title, List<Map<String, dynamic>> items) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5F5F7),
    appBar: AppBar(
      title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black87,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildSubCard(context, items[index]),
      ),
    ),
  );
}

Widget _buildSubCard(BuildContext context, Map<String, dynamic> mode) {
  return Stack(
    children: [
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ModeDetailPage(title: mode['title'], icon: mode['icon'], desc: mode['desc']),
                ));
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(mode['icon'], size: 32, color: Colors.blueGrey),
                const SizedBox(height: 10),
                Text(mode['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(mode['desc'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
          ),
        ),
      ),
      if (mode['alert'] > 0)
        Positioned(right: 12, top: 12, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
    ],
  );
}