class TeacherSession {
  final String sessionId;
  final String materialId;
  final double accuracy;
  final double fluency;
  final String feedback;

  TeacherSession({
    required this.sessionId,
    required this.materialId,
    this.accuracy = 0.0,
    this.fluency = 0.0,
    this.feedback = '',
  });
}