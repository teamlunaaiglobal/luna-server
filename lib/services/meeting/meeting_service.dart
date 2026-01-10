import 'package:flutter/foundation.dart';
import '../../models/meeting/meeting_record.dart';
import '../../models/meeting/transcript.dart';
import '../../models/meeting/action_item.dart';
import '../../data/meeting_repository.dart';
import 'meeting_recorder.dart';
import 'meeting_transcriber.dart';
import 'meeting_summarizer.dart';
import 'action_item_extractor.dart';

class MeetingService {
  static final MeetingService instance = MeetingService._internal();
  factory MeetingService() => instance;
  MeetingService._internal();

  final MeetingRepository _repo = MeetingRepository.instance;
  final MeetingRecorder _recorder = MeetingRecorder.instance;
  final MeetingTranscriber _transcriber = MeetingTranscriber.instance;
  final MeetingSummarizer _summarizer = MeetingSummarizer.instance;
  final ActionItemExtractor _extractor = ActionItemExtractor.instance;

  MeetingRecord? _currentMeeting;
  Transcript? _currentTranscript;
  
  bool _isInitialized = false;

  bool get isRecording => _recorder.isRecording;
  MeetingRecord? get currentMeeting => _currentMeeting;

  /// 초기화
  Future<void> init() async {
    if (_isInitialized) return;
    await _repo.init();
    await _transcriber.init();
    _isInitialized = true;
    debugPrint('📋 MeetingService 초기화 완료');
  }

  /// 회의 시작 (녹음 + 실시간 전사)
  Future<String> startMeeting({
    String? title,
    Function(String)? onTranscript,
  }) async {
    if (!_isInitialized) await init();
    
    if (isRecording) {
      return "이미 회의 녹음 중이에요.";
    }

    // 녹음 시작
    _currentMeeting = await _recorder.startRecording(title: title);
    if (_currentMeeting == null) {
      return "녹음을 시작하지 못했어요. 마이크 권한을 확인해주세요.";
    }

    // 저장
    await _repo.addMeeting(_currentMeeting!);

    // 실시간 전사 시작
    await _transcriber.startTranscribing(
      onResult: (text) {
        debugPrint('📝 전사: $text');
        onTranscript?.call(text);
        
        // 실시간 액션 아이템 감지
        if (_extractor.detectActionItem(text)) {
          debugPrint('⚡ 액션 아이템 감지: $text');
        }
      },
    );

    debugPrint('🎬 회의 시작: ${_currentMeeting!.title}');
    return "🎙️ 회의 녹음을 시작했어요! '${_currentMeeting!.title}'";
  }

  /// 회의 종료 (녹음 중지 + 요약 + 액션 아이템 추출)
  Future<String> endMeeting() async {
    if (!isRecording || _currentMeeting == null) {
      return "진행 중인 회의가 없어요.";
    }

    // 전사 종료
    _currentTranscript = await _transcriber.stopTranscribing(_currentMeeting!.id);
    
    // 녹음 종료
    final completedMeeting = await _recorder.stopRecording();
    if (completedMeeting == null) {
      return "녹음 종료에 실패했어요.";
    }

    final transcript = _currentTranscript?.fullText ?? '';
    
    // AI 요약 생성
    String summary = '';
    if (transcript.isNotEmpty) {
      summary = await _summarizer.summarize(transcript, meetingTitle: completedMeeting.title);
    }

    // 액션 아이템 추출
    List<ActionItem> actionItems = [];
    if (transcript.isNotEmpty) {
      actionItems = await _extractor.extract(transcript, completedMeeting.id);
      for (var item in actionItems) {
        await _repo.addActionItem(item);
      }
    }

    // 회의 기록 업데이트
    final finalMeeting = completedMeeting.copyWith(
      transcript: transcript,
      summary: summary,
      status: MeetingStatus.completed,
    );
    await _repo.updateMeeting(finalMeeting);

    _currentMeeting = null;
    _currentTranscript = null;

    // 결과 메시지
    final duration = finalMeeting.durationMinutes;
    final result = StringBuffer();
    result.writeln("⏹️ 회의 종료! ($duration분)");
    result.writeln("");
    if (summary.isNotEmpty) {
      result.writeln(summary);
    }
    if (actionItems.isNotEmpty) {
      result.writeln("");
      result.writeln("📌 추출된 할일 ${actionItems.length}개:");
      for (var item in actionItems) {
        result.writeln("  • ${item.content}");
      }
    }

    debugPrint('🎬 회의 종료: ${finalMeeting.title}');
    return result.toString();
  }

  /// 회의 취소
  Future<String> cancelMeeting() async {
    if (!isRecording) {
      return "진행 중인 회의가 없어요.";
    }

    await _transcriber.stopTranscribing(_currentMeeting?.id ?? '');
    await _recorder.cancelRecording();
    
    if (_currentMeeting != null) {
      await _repo.deleteMeeting(_currentMeeting!.id);
    }

    _currentMeeting = null;
    _currentTranscript = null;

    return "🗑️ 회의 녹음을 취소했어요.";
  }

  /// 최근 회의 목록
  List<MeetingRecord> getRecentMeetings({int limit = 10}) {
    return _repo.getRecentMeetings(limit: limit);
  }

  /// 회의 상세 조회
  MeetingRecord? getMeeting(String id) {
    return _repo.getMeeting(id);
  }

  /// 미완료 액션 아이템 조회
  List<ActionItem> getPendingActionItems() {
    return _repo.getPendingActionItems();
  }

  /// 회의 관련 입력인지 확인
  static bool canHandle(String input) {
    final lower = input.toLowerCase();
    return lower.contains('회의 시작') ||
           lower.contains('회의 녹음') ||
           lower.contains('회의 끝') ||
           lower.contains('회의 종료') ||
           lower.contains('회의 취소') ||
           lower.contains('회의록') ||
           lower.contains('meeting');
  }

  /// 회의 관련 처리
  Future<String> handle(String input) async {
    final lower = input.toLowerCase();

    if (lower.contains('회의 시작') || lower.contains('회의 녹음')) {
      String? title;
      // "OO 회의 시작" 에서 제목 추출
      final match = RegExp(r'(.+?)\s*회의\s*(시작|녹음)').firstMatch(input);
      if (match != null && match.group(1)!.trim().isNotEmpty) {
        title = '${match.group(1)!.trim()} 회의';
      }
      return await startMeeting(title: title);
    }

    if (lower.contains('회의 끝') || lower.contains('회의 종료')) {
      return await endMeeting();
    }

    if (lower.contains('회의 취소')) {
      return await cancelMeeting();
    }

    if (lower.contains('회의록') || lower.contains('최근 회의')) {
      final meetings = getRecentMeetings(limit: 5);
      if (meetings.isEmpty) {
        return "저장된 회의록이 없어요.";
      }
      final list = meetings.map((m) => 
        "• ${m.title} (${m.startTime.month}/${m.startTime.day}, ${m.durationMinutes}분)"
      ).join('\n');
      return "📋 최근 회의록:\n$list";
    }

    return "";
  }
}
