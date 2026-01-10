enum AnniversaryType {
  birthday,
  wedding,
  dating,
  memorial,
  custom,
}

class Anniversary {
  final String id;
  final String name;              // "아내 생일", "결혼기념일"
  final AnniversaryType type;
  final int month;
  final int day;
  final int? year;                // 시작 연도 (몇 주년 계산용)
  final bool isLunar;             // 음력 여부
  final List<String> checklist;   // 체크리스트 항목

  Anniversary({
    required this.id,
    required this.name,
    required this.type,
    required this.month,
    required this.day,
    this.year,
    this.isLunar = false,
    this.checklist = const [],
  });

  /// D-day 계산
  int getDday() {
    final now = DateTime.now();
    var thisYear = DateTime(now.year, month, day);
    if (thisYear.isBefore(now)) {
      thisYear = DateTime(now.year + 1, month, day);
    }
    return thisYear.difference(now).inDays;
  }

  /// 몇 주년인지 계산
  int? getYearsCount() {
    if (year == null) return null;
    return DateTime.now().year - year!;
  }
}