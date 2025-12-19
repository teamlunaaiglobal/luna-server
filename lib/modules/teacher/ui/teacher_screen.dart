import 'package:flutter/material.dart';
import '../services/teacher_ai_service.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final TeacherAIService _aiService = TeacherAIService.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  // 학습 통계 데이터 로드
  Future<void> _loadStatistics() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final history = _aiService.getLearningHistory();
    double totalScore = 0;
    int count = 0;
    
    history.forEach((_, v) {
      // [수정] totalScore 계산 (레벨 * 10점 만점 기준 시뮬레이션)
      totalScore += (v['level'] ?? 0) * 10; 
      count++;
    });

    if (mounted) {
      setState(() {
        _stats = {
          'level': 3.5, 
          'next_level_progress': 0.7, 
          'total_sessions': count,
          // [수정] totalScore 변수를 사용하여 실제 평균 점수 계산 (경고 해결)
          'avg_score': count > 0 ? (totalScore / count).clamp(0, 100).toInt() : 0,
          'weakness': ['Pronunciation', 'Past Tense'], 
          'recent_history': [
            {'title': 'Business Meeting', 'score': 92, 'date': 'Today'},
            {'title': 'Travel Booking', 'score': 85, 'date': 'Yesterday'},
            {'title': 'Daily Greeting', 'score': 98, 'date': '2 days ago'},
          ]
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Progress Report"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 레벨 카드
                  _buildLevelCard(),
                  const SizedBox(height: 24),

                  // 2. 통계 그리드
                  Row(
                    children: [
                      Expanded(child: _buildStatItem("Total Classes", "${_stats['total_sessions']}")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatItem("Avg. Score", "${_stats['avg_score']}")),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. AI 분석 리포트
                  const Text("AI Weakness Analysis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAnalysisCard(),
                  const SizedBox(height: 24),

                  // 4. 최근 학습 이력
                  const Text("Recent History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // [수정] .toList() 제거 (경고 해결) - map() 결과는 iterable이므로 바로 spread 가능
                  ...(_stats['recent_history'] as List).map((h) => _buildHistoryItem(h)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
      
      // 하단: 학습하러 가기 버튼
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(context); 
          },
          child: const Text("Go to Class (Start Learning)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.withValues(alpha: 0.8), Colors.teal.withValues(alpha: 0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Current Level", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Lv.${_stats['level']}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                child: const Text("Intermediate", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("To Next Level", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _stats['next_level_progress'],
            backgroundColor: Colors.black26,
            color: Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final weaknesses = _stats['weakness'] as List;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text("Focus Areas", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: weaknesses.map((w) => Chip(
              label: Text(w),
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: Colors.white),
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.tealAccent, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(history['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text("${history['score']} pts", style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}