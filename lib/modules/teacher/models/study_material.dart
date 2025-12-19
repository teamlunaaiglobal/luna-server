class StudyMaterial {
  final String id;
  final String type; // 'news', 'script', 'scenario'
  final String title;
  final String contentOriginal;
  final String contentTranslated;
  final double difficultyLevel; // 1.0 ~ 10.0
  final List<String> keywords;
  final DateTime createdAt;

  StudyMaterial({
    required this.id,
    required this.type,
    required this.title,
    required this.contentOriginal,
    required this.contentTranslated,
    required this.difficultyLevel,
    required this.keywords,
    required this.createdAt,
  });
}