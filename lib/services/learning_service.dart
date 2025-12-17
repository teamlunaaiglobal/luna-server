import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LearningService {
  static final LearningService _instance = LearningService._internal();
  factory LearningService() => _instance;
  LearningService._internal();

  final Random _rand = Random();
  final List<Map<String, String>> _quizItems = [
    {'question': 'Apple', 'answer': '사과'}, {'question': 'Innovation', 'answer': '혁신'},
    {'question': 'Passion', 'answer': '열정'}, {'question': 'Destiny', 'answer': '운명'},
  ];
  List<Map<String, String>> _notebook = [];

  Future<void> loadNotebook() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('learning_notebook');
    if (data != null) {
      List<dynamic> decoded = jsonDecode(data);
      _notebook = decoded.map((e) => Map<String, String>.from(e)).toList();
    }
  }

  // ★ 문법 체크 시뮬레이션
  Map<String, String>? checkGrammar(String input) {
    String lower = input.toLowerCase();
    if (lower.contains("i go school")) return {'wrong': input, 'correct': "I went to school"};
    if (lower.contains("he like")) return {'wrong': input, 'correct': "He likes"};
    return null;
  }

  // ★ 오답 노트 자동 저장
  Future<void> saveToNotebook(String wrong, String correct) async {
    _notebook.insert(0, {'wrong': wrong, 'correct': correct, 'date': DateTime.now().toString().split(' ')[0]});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning_notebook', jsonEncode(_notebook));
  }

  Map<String, String> getRandomQuestion() => _quizItems[_rand.nextInt(_quizItems.length)];
  bool checkAnswer(String input, String answer) => input.trim().replaceAll(" ", "").toLowerCase() == answer.trim().replaceAll(" ", "").toLowerCase();
}