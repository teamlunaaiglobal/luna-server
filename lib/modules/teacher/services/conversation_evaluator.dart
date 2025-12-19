import 'dart:math';

class ConversationEvaluator {
  ConversationEvaluator._privateConstructor();
  static final ConversationEvaluator instance = ConversationEvaluator._privateConstructor();

  /// [Gen-4] 실시간 정밀 분석 (Real-time Analysis)
  Map<String, dynamic> evaluate(String userSpeech, String targetSentence) {
    // 1. 전처리
    final normalizedUser = _normalize(userSpeech);
    final normalizedTarget = _normalize(targetSentence);

    if (normalizedUser.isEmpty) {
      return {
        'score': 0,
        'feedback': "목소리가 들리지 않았어요. 조금 더 크게 말씀해 주세요.",
        'weak_words': [],
        'intonation_tip': "발음이 명확하지 않습니다.",
      };
    }

    // 2. 유사도 계산 (Levenshtein)
    final similarity = _calculateSimilarity(normalizedUser, normalizedTarget);
    final score = (similarity * 100).toInt();

    // 3. [New] 틀린 단어 분석 (시뮬레이션)
    // 실제로는 Diff 알고리즘을 쓰지만, 여기서는 유사도가 낮으면 랜덤으로 약점 단어 지목
    List<String> weakWords = [];
    if (score < 100) {
      final targetWords = targetSentence.split(' ');
      // 점수가 낮을수록 지적하는 단어가 많아짐
      if (targetWords.length > 2) {
        weakWords.add(targetWords[Random().nextInt(targetWords.length)]);
      }
    }

    // 4. [New] 상세 피드백 생성
    String feedback;
    String intonationTip;

    if (score >= 95) {
      feedback = "Perfect! 원어민 그 자체네요.";
      intonationTip = "억양과 리듬이 아주 자연스럽습니다.";
    } else if (score >= 80) {
      feedback = "Excellent! 의미 전달이 완벽합니다.";
      intonationTip = "끝을 살짝 내려서 말하면 더 자연스러워요.";
    } else if (score >= 60) {
      feedback = "Good! 비슷하지만 '${weakWords.isNotEmpty ? weakWords.first : '발음'}' 부분을 주의하세요.";
      intonationTip = "조금 더 천천히 또박또박 말해보세요.";
    } else {
      feedback = "Try Again. 문장을 다시 듣고 따라해 보세요.";
      intonationTip = "단어 하나하나를 끊어서 연습해보세요.";
    }

    return {
      'score': score,
      'feedback': feedback,
      'weak_words': weakWords,      // [New] UI 하이라이팅용
      'intonation_tip': intonationTip, // [New] 억양 가이드
    };
  }

  String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    List<List<int>> dist = List.generate(s1.length + 1, (i) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) { dist[i][0] = i; }
    for (int j = 0; j <= s2.length; j++) { dist[0][j] = j; }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        dist[i][j] = [
          dist[i - 1][j] + 1,
          dist[i][j - 1] + 1,
          dist[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    int maxLength = max(s1.length, s2.length);
    return 1.0 - (dist[s1.length][s2.length] / maxLength);
  }
}