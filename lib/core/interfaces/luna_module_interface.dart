enum LunaMode {
  auto,    // 자동
  friend,  // 친구
  assist,  // 비서
  system,  // 시스템 [필수 추가]
  tutor    // 학습 [필수 추가]
}

abstract class LunaModule {
  String get id;
  List<LunaMode> get supportedModes;
  Future<void> initialize();
  Future<dynamic> execute(String command);
  Future<void> handleFailure(String error);
}