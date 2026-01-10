import 'package:flutter/material.dart';
import '../../../widgets/luen_colors.dart';

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep, // 리얼 블랙
      appBar: AppBar(
        backgroundColor: LuenColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        // [타이틀 변경] AI TUTOR
        title: const Text("AI TUTOR", 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontFamily: "Courier", 
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          // 네온 구분선
          child: Container(color: LuenColors.neonPoint.withValues(alpha: 0.2), height: 1.0), 
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 상단 안내 문구 (const 적용 완료)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: LuenColors.neonPoint, size: 18),
                  SizedBox(width: 10),
                  Text(
                    "LEARNING MODULES", // 튜터니까 "학습 모듈"로 변경
                    style: TextStyle(color: LuenColors.neonPoint, fontSize: 12, letterSpacing: 1.5, fontFamily: "Courier"),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),

            // [메뉴 리스트] - 학습 관련 내용으로 구성
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // 1. 수업 시작
                  _buildSectionTitle("CLASSROOM"),
                  _buildFunctionItem(context, "Start New Session", "새로운 주제로 수업 시작", Icons.school_outlined),
                  _buildFunctionItem(context, "Continue Learning", "지난 수업 이어하기", Icons.history_edu),
                  
                  const SizedBox(height: 30),

                  // 2. 복습 및 평가
                  _buildSectionTitle("REVIEW & TEST"),
                  _buildFunctionItem(context, "Daily Quiz", "오늘 배운 내용 퀴즈", Icons.quiz_outlined),
                  _buildFunctionItem(context, "Mistake Note", "오답 노트 및 복습", Icons.note_alt_outlined),

                  const SizedBox(height: 30),

                  // 3. 분석
                  _buildSectionTitle("ANALYTICS"),
                  _buildFunctionItem(context, "Progress Report", "학습 진도율 확인", Icons.pie_chart_outline),
                  _buildFunctionItem(context, "Weakness Analysis", "취약점 분석 리포트", Icons.insights),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 섹션 제목 위젯 (비서 화면과 동일)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  // 기능 아이템 위젯 (비서 화면과 동일)
  Widget _buildFunctionItem(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          splashColor: LuenColors.neonPoint.withValues(alpha: 0.1),
          highlightColor: LuenColors.neonPoint.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LuenColors.neonPoint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: LuenColors.neonPoint, size: 20),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500, 
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}