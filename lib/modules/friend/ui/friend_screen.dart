import 'package:flutter/material.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 테마 컬러 상수 정의
    const Color bgWarm = Color(0xFFFFF5F6); // 따뜻한 핑크 화이트
    const Color textBrown = Color(0xFF5D4037); // 차분한 브라운 텍스트
    const Color cardWhite = Colors.white;
    const Color accentPink = Color(0xFFFFB2C1); // 포인트 파스텔 핑크

    return Scaffold(
      backgroundColor: bgWarm,
      appBar: AppBar(
        backgroundColor: bgWarm,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("MY BESTIE", 
          style: TextStyle(
            color: textBrown, 
            fontSize: 18, 
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0
          )
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          // withValues는 여기서 유지 (PreferredSize child는 const 강제가 아님)
          child: Container(color: accentPink.withValues(alpha: 0.3), height: 1.0), 
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // 1. EMOTIONAL STATUS (오늘의 기분)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(20),
                // [수정 완료] const 적용을 위해 고정 컬러값 사용 (0x0D000000 = Black 5%)
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000), 
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: bgWarm,
                      shape: BoxShape.circle,
                    ),
                    child: const Text("🥰", style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Mood", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        SizedBox(height: 4),
                        Text("기분이 아주 좋아요!", style: TextStyle(color: textBrown, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("대표님과 대화해서 그런가 봐요.", style: TextStyle(color: textBrown, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. SHARED MEMORIES (사진첩)
            const Text("OUR MEMORIES", style: TextStyle(color: textBrown, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
              ),
              itemCount: 4, 
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: NetworkImage("https://picsum.photos/200"),
                      fit: BoxFit.cover,
                      opacity: 0.9,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                      ),
                      child: Text(
                        "Memory #${index + 1}",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // 3. DIARY LOGS (다이어리)
            const Text("DIARY LOGS", style: TextStyle(color: textBrown, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildDiaryItem(cardWhite, textBrown, "Dec 20", "여친이랑 중국 여행 계획 짬.", "✈️"),
            _buildDiaryItem(cardWhite, textBrown, "Dec 19", "쌍둥이 육아 힘들다고 하소연함.", "👶"),
            _buildDiaryItem(cardWhite, textBrown, "Dec 18", "LUNA 앱 개발 아이디어 공유.", "💡"),
          ],
        ),
      ),
    );
  }

  // 다이어리 아이템 위젯
  Widget _buildDiaryItem(Color cardColor, Color textColor, String date, String content, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}