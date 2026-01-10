import 'package:flutter/material.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [배경] 완전한 리얼 블랙
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("AGENT CONSOLE", 
          style: TextStyle(
            color: Colors.white, 
            fontSize: 14, 
            fontFamily: "Courier", 
            letterSpacing: 3.0,
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0), 
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 최상단 상태 브리핑
              const Text(
                "SYSTEM STATUS",
                style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                "ALL SYSTEMS OPERATIONAL",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 40),

              // 2. 핵심 지표
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricItem("BATTERY", "85%", true),
                  _buildVerticalLine(),
                  _buildMetricItem("TASKS", "04", false),
                  _buildVerticalLine(),
                  _buildMetricItem("EVENTS", "02", false),
                ],
              ),

              const SizedBox(height: 40),

              // 3. 작업 리스트 헤더
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PENDING TASKS",
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2.0),
                  ),
                  Icon(Icons.sort, color: Colors.white30, size: 18),
                ],
              ),
              const SizedBox(height: 20),

              // 4. 작업 리스트
              Expanded(
                child: ListView(
                  children: [
                    _buildMinimalTaskItem("01", "Project LUNA Launch", "D-DAY: 2025.12.16", true),
                    _buildMinimalTaskItem("02", "Server Maintenance", "Scheduled: 03:00 AM", false),
                    _buildMinimalTaskItem("03", "UI/UX Design Review", "Waiting for approval", false),
                    _buildMinimalTaskItem("04", "Battery Optimization", "Analysis required", false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // [플로팅 버튼]
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.mic, color: Colors.black),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isHighlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, 
          style: TextStyle(
            color: isHighlight ? Colors.cyanAccent : Colors.white, 
            fontSize: 28, 
            fontWeight: FontWeight.bold,
            fontFamily: "Courier"
          )
        ),
      ],
    );
  }

  Widget _buildVerticalLine() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white12,
    );
  }

  Widget _buildMinimalTaskItem(String index, String title, String subTitle, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(index, 
            style: const TextStyle(color: Colors.white30, fontSize: 14, fontFamily: "Courier")
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: TextStyle(
                    color: isUrgent ? Colors.white : Colors.white70, 
                    fontSize: 16,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal
                  )
                ),
                const SizedBox(height: 4),
                Text(subTitle, 
                  // [핵심 수정] withOpacity -> withValues (최신 문법)
                  style: TextStyle(
                    color: isUrgent ? Colors.cyanAccent.withValues(alpha: 0.7) : Colors.white24, 
                    fontSize: 12
                  )
                ),
              ],
            ),
          ),
          if (isUrgent)
            const Icon(Icons.circle, size: 8, color: Colors.cyanAccent)
        ],
      ),
    );
  }
}