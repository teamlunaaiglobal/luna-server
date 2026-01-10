import 'package:flutter/material.dart';
import '../../widgets/luen_colors.dart';

// ---------------------------------------------------------
// 1. [메인] AssistantScreen
// ---------------------------------------------------------
class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep, 
      appBar: AppBar(
        backgroundColor: LuenColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("AI SECRETARY", 
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Courier", letterSpacing: 2.0, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: LuenColors.neonPoint.withValues(alpha: 0.2), height: 1.0), 
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Icon(Icons.terminal, color: LuenColors.neonPoint, size: 18),
                  SizedBox(width: 10),
                  Text("SYSTEM READY", style: TextStyle(color: LuenColors.neonPoint, fontSize: 12, letterSpacing: 1.5, fontFamily: "Courier")),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // 1. MORNING BRIEFING
                  _buildSectionTitle("MORNING BRIEFING"),
                  _buildFunctionItem(
                    context, "Daily Summary", "오늘의 일정 및 할 일 브리핑", Icons.pie_chart_outline,
                    targetScreen: const DailyBriefingScreen()
                  ),
                  _buildFunctionItem(
                    context, "Commute & Weather", "출근길 날씨 및 교통 체크", Icons.cloud_circle_outlined,
                    targetScreen: const ReportDetailScreen(title: "Environment", content: "날씨 상세 정보...")
                  ),

                  const SizedBox(height: 30),

                  // 2. MY WORKSTATION (핵심)
                  _buildSectionTitle("MY WORKSTATION"),
                  _buildFunctionItem(
                    context, 
                    "My Performance", // 이름 변경: Work Dashboard -> My Performance
                    "업무 현황 및 캡처 결과물 확인", 
                    Icons.dashboard_customize_outlined, 
                    isHighlight: true,
                    targetScreen: const BusinessDashboardScreen() 
                  ),
                  _buildFunctionItem(
                    context, "Meeting Notes", "내가 작성한 회의록", Icons.edit_document,
                    targetScreen: const ReportDetailScreen(title: "My Notes", content: "회의록 리스트...")
                  ),

                  const SizedBox(height: 30),

                  // 3. ARCHIVES
                  _buildSectionTitle("ARCHIVES"),
                  _buildFunctionItem(
                    context, "Research Scrap", "웹 자료 조사 스크랩북", Icons.bookmark_border,
                    targetScreen: const ReportDetailScreen(title: "Scraps", content: "스크랩 결과...")
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, left: 5),
      child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
    );
  }

  Widget _buildFunctionItem(BuildContext context, String title, String subtitle, IconData icon, {required Widget targetScreen, bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlight ? LuenColors.neonPoint.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen)); },
          splashColor: LuenColors.neonPoint.withValues(alpha: 0.1),
          highlightColor: LuenColors.neonPoint.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: LuenColors.neonPoint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Icon(icon, color: LuenColors.neonPoint, size: 20),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isHighlight ? LuenColors.neonPoint : Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: isHighlight ? LuenColors.neonPoint : Colors.grey, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. [Business Dashboard] 디자인 통일 & 결과물 통합
// ---------------------------------------------------------
class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep,
      appBar: AppBar(
        backgroundColor: LuenColors.bgDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        // [디자인 통일] Courier 폰트와 간격 조정
        title: const Text("MY PERFORMANCE", 
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Courier", letterSpacing: 2.0, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: LuenColors.neonPoint.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. STATUS MONITOR (숫자 카드)
          const Text("STATUS MONITOR", style: TextStyle(color: LuenColors.neonPoint, fontSize: 12, fontFamily: "Courier", fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          Row(
            children: [
              _buildNeonMetricCard("TASKS", "80%", "8 / 10 Done", Icons.check_circle_outline, Colors.greenAccent),
              const SizedBox(width: 12),
              _buildNeonMetricCard("MEETINGS", "BUSY", "3 Scheduled", Icons.calendar_today, Colors.blueAccent),
            ],
          ),

          const SizedBox(height: 35),

          // 2. DEADLINE ALERT (마감 관리)
          const Text("DEADLINE ALERT", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: "Courier", fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          _buildAlertCard(context, "Weekly Report", "Today 18:00", "D-DAY", Colors.redAccent),
          _buildAlertCard(context, "Expense Receipt", "Tomorrow 10:00", "D-1", Colors.orangeAccent),

          const SizedBox(height: 35),

          // 3. LATEST CAPTURES (여기가 핵심: 명함/스캔 확인)
          // [디자인 통일] 단순 리스트가 아니라, "파일 보관함" 느낌의 디자인 적용
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("LATEST CAPTURES", style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: "Courier", fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: const Text("VIEW ALL", style: TextStyle(color: Colors.grey, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 15),

          // [결과물 카드 리스트]
          _buildAssetCard(
            context,
            "BizCard_CEO.jpg", 
            "CONTACT ADDED", 
            "홍길동 대표이사\n(주)테크솔루션\n010-1234-5678", 
            Icons.contact_mail_outlined, 
            Colors.pinkAccent
          ),
          _buildAssetCard(
            context,
            "Contract_Scan.pdf", 
            "PDF SAVED", 
            "2025 표준 근로계약서\nPage 1 of 5\nSize: 2.4MB", 
            Icons.picture_as_pdf_outlined, 
            Colors.cyanAccent
          ),
          _buildAssetCard(
            context,
            "Meeting_Whiteboard.txt", 
            "TEXT EXTRACTED", 
            "[회의 내용 추출]\n1. 런칭 일정 확정\n2. 마케팅 예산 증액...", 
            Icons.text_fields_rounded, 
            Colors.yellowAccent
          ),
        ],
      ),
    );
  }

  // [위젯] 네온 스타일 메트릭 카드 (디자인 통일됨)
  Widget _buildNeonMetricCard(String title, String bigText, String subText, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A), // 통일된 배경색
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)), // 네온 테두리
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 0)
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Text(title, style: TextStyle(color: color, fontSize: 10, fontFamily: "Courier", fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(bigText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subText, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // [위젯] 경고 스타일 마감 카드
  Widget _buildAlertCard(BuildContext context, String title, String time, String tag, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.5))
            ),
            child: Text(tag, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 10),
        ],
      ),
    );
  }

  // [위젯] 결과물(자산) 카드 - 여기가 명함/문서 보여주는 곳
  Widget _buildAssetCard(BuildContext context, String fileName, String status, String previewText, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ReportDetailScreen(title: "ASSET VIEWER", content: "[$fileName]\n\n$previewText")));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 아이콘 영역
            Container(
              width: 60,
              height: 80, // 높이 고정
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            // 우측: 정보 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(status, style: TextStyle(color: color, fontSize: 10, fontFamily: "Courier", fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      previewText, 
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// [기타 화면들] (유지)
// ---------------------------------------------------------
class DailyBriefingScreen extends StatelessWidget {
  const DailyBriefingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuenColors.bgDeep,
      appBar: AppBar(title: const Text("DAILY SUMMARY", style: TextStyle(color: Colors.white)), backgroundColor: LuenColors.bgDeep),
      body: const Center(child: Text("Daily Summary List", style: TextStyle(color: Colors.white))),
    );
  }
}
class ReportDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  const ReportDetailScreen({super.key, required this.title, required this.content});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.grey)),
      body: Padding(padding: const EdgeInsets.all(20), child: Text(content, style: const TextStyle(color: Colors.white, height: 1.5))),
    );
  }
}