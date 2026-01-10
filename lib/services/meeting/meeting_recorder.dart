import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../models/meeting/meeting_record.dart';

class MeetingRecorder {
  static final MeetingRecorder instance = MeetingRecorder._internal();
  factory MeetingRecorder() => instance;
  MeetingRecorder._internal();

  final AudioRecorder _recorder = AudioRecorder();
  
  MeetingRecord? _currentMeeting;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  MeetingRecord? get currentMeeting => _currentMeeting;

  /// 녹음 시작
  Future<MeetingRecord?> startRecording({String? title}) async {
    if (_isRecording) {
      debugPrint('⚠️ 이미 녹음 중입니다.');
      return null;
    }

    // 권한 확인
    if (!await _recorder.hasPermission()) {
      debugPrint('❌ 마이크 권한이 없습니다.');
      return null;
    }

    try {
      // 파일 경로 생성
      final dir = await getApplicationDocumentsDirectory();
      final meetingId = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${dir.path}/meetings/$meetingId.m4a';
      
      // 폴더 생성
      final meetingDir = Directory('${dir.path}/meetings');
      if (!await meetingDir.exists()) {
        await meetingDir.create(recursive: true);
      }

      // 녹음 시작
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      
      // 회의 기록 생성
      _currentMeeting = MeetingRecord(
        id: meetingId,
        title: title ?? '회의 $meetingId',
        startTime: DateTime.now(),
        audioPath: filePath,
        status: MeetingStatus.recording,
      );

      debugPrint('🎙️ 녹음 시작: $filePath');
      return _currentMeeting;

    } catch (e) {
      debugPrint('❌ 녹음 시작 실패: $e');
      return null;
    }
  }

  /// 녹음 종료
  Future<MeetingRecord?> stopRecording() async {
    if (!_isRecording || _currentMeeting == null) {
      debugPrint('⚠️ 녹음 중이 아닙니다.');
      return null;
    }

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      final completedMeeting = _currentMeeting!.copyWith(
        endTime: DateTime.now(),
        audioPath: path,
        status: MeetingStatus.processing,
      );

      _currentMeeting = null;
      
      debugPrint('⏹️ 녹음 종료: $path');
      debugPrint('⏱️ 녹음 시간: ${completedMeeting.durationMinutes}분');
      
      return completedMeeting;

    } catch (e) {
      debugPrint('❌ 녹음 종료 실패: $e');
      return null;
    }
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
      
      // 파일 삭제
      if (_currentMeeting?.audioPath != null) {
        final file = File(_currentMeeting!.audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _currentMeeting = null;
      debugPrint('🗑️ 녹음 취소됨');
    }  
  }

  /// 리소스 해제
  void dispose() {
    _recorder.dispose();
  }
}