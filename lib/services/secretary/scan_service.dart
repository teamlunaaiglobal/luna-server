import '../../core/memory_service.dart';
import '../hardware/luna_vision_service.dart';

class ScanService {
  static final ScanService instance = ScanService._internal();
  factory ScanService() => instance;
  ScanService._internal();

  final MemoryService _memory = MemoryService();

  /// 스캔 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('영수증') || 
           lower.contains('receipt') || 
           lower.contains('스캔') ||
           lower.contains('명함') || 
           lower.contains('business card') || 
           lower.contains('연락처 추가');
  }

  /// 스캔 처리
  Future<String> handle(String input) async {
    final lower = input.toLowerCase();

    if (lower.contains('영수증') || lower.contains('receipt') || lower.contains('스캔')) {
      return await scanReceipt();
    }

    if (lower.contains('명함') || lower.contains('business card') || lower.contains('연락처 추가')) {
      return await scanBusinessCard();
    }

    return "";
  }

  /// 영수증 스캔
  Future<String> scanReceipt() async {
    String result = await LunaVisionService.instance.scanReceipt();
    if (result.contains('취소') || result.contains('인식하지')) {
      return result;
    }
    await _memory.addItem('receipt', result);
    return "📄 영수증 스캔 완료!\n\n$result";
  }

  /// 명함 스캔
  Future<String> scanBusinessCard() async {
    String result = await LunaVisionService.instance.scanBusinessCard();
    if (result.contains('취소') || result.contains('인식하지')) {
      return result;
    }
    await _memory.addItem('contact', result);
    return "📇 명함 스캔 완료!\n\n$result";
  }
}
