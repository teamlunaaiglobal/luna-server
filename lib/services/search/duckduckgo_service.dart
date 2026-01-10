import 'dart:convert';
import 'package:http/http.dart' as http;

class DuckDuckGoService {
  static final DuckDuckGoService instance = DuckDuckGoService._internal();
  factory DuckDuckGoService() => instance;
  DuckDuckGoService._internal();

  /// DuckDuckGo Instant Answer API 호출
  Future<String> search(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final url = 'https://api.duckduckgo.com/?q=$encoded&format=json&no_html=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Abstract (요약) 있으면 반환
        if (data['Abstract'] != null && data['Abstract'].toString().isNotEmpty) {
          return data['Abstract'];
        }
        
        // Answer 있으면 반환
        if (data['Answer'] != null && data['Answer'].toString().isNotEmpty) {
          return data['Answer'];
        }
        
        // RelatedTopics 있으면 첫 번째 반환
        if (data['RelatedTopics'] != null && data['RelatedTopics'].isNotEmpty) {
          var first = data['RelatedTopics'][0];
          if (first['Text'] != null) {
            return first['Text'];
          }
        }
        
        return "검색 결과를 찾지 못했어.";
      }
      return "검색 중 오류가 발생했어.";
    } catch (e) {
      return "검색 연결에 실패했어.";
    }
  }
}
