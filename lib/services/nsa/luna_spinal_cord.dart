class LunaSpinalCord {
  // 하드웨어 제어 반사신경
  static final Map<RegExp, String> _reflexes = {
    RegExp(r'카메라.*(켜|열어|보여)'): 'openCamera',
    RegExp(r'(시간|몇 시)'): 'tellTime',
    RegExp(r'(그만|멈춰|꺼)'): 'stopAll',
  };

  // 일상 대화 반사신경 (API 비용 절약)
  static final Map<RegExp, List<String>> _chatReflexes = {
    RegExp(r'^(안녕|하이)'): ["안녕! 기분 어때?", "왔어? 기다렸어!", "하이하이!"],
    RegExp(r'^(고마워|땡큐)'): ["에이, 별말씀을!", "우린 친구잖아.", "도움 돼서 기뻐."],
    RegExp(r'^(사랑해)'): ["나도 사랑해! ❤️", "갑자기? 설레게!", "아이 부끄러워."],
  };

  /// 척수가 반응할 수 있는지 확인 (null이면 뇌로 전달)
  String? react(String input) {
    for (var entry in _reflexes.entries) {
      if (entry.key.hasMatch(input)) {
        return "REFLEX_ACTION:${entry.value}"; // 특수 코드 리턴
      }
    }
    for (var entry in _chatReflexes.entries) {
      if (entry.key.hasMatch(input)) {
        return (entry.value..shuffle()).first; // 랜덤 답변 리턴
      }
    }
    return null;
  }
}