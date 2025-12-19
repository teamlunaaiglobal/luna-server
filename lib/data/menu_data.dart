import 'package:flutter/material.dart';

class MenuFunction {
  final String category;
  final String group;
  final String title;
  final IconData icon;
  final String actionId;

  MenuFunction({
    required this.category,
    required this.group,
    required this.title,
    required this.icon,
    required this.actionId,
  });
}

class LunaMenuData {
  static final List<MenuFunction> assistantFunctions = [
    // ==============================================================================
    // [탭 1] 비서 업무 (Secretary)
    // ==============================================================================

    // 1-0. 스마트 브리핑 (Briefing) - 달력/업무 요약의 핵심
    MenuFunction(category: "비서", group: "브리핑", title: "오늘의 일정/업무 요약", icon: Icons.dashboard, actionId: "brief_today"), // 달력 연동
    MenuFunction(category: "비서", group: "브리핑", title: "내일 일정 미리보기", icon: Icons.calendar_today, actionId: "brief_tomorrow"), // 달력 연동
    MenuFunction(category: "비서", group: "브리핑", title: "최근 업무 흐름", icon: Icons.history, actionId: "brief_flow"),
    MenuFunction(category: "비서", group: "브리핑", title: "기능/업무 검색", icon: Icons.search, actionId: "brief_search"),

    // 1-1. 일정 액션 (Schedule Action) - 보는 건 달력에서, 루나는 '판단'만
    MenuFunction(category: "비서", group: "일정", title: "이동시간 계산/조정", icon: Icons.directions_run, actionId: "sch_move_time"), // 스마트 기능
    MenuFunction(category: "비서", group: "일정", title: "회의 일정 자동등록", icon: Icons.event_available, actionId: "sch_auto_add"), // 텍스트->달력 입력
    MenuFunction(category: "비서", group: "일정", title: "일정 기반 할 일 생성", icon: Icons.playlist_add, actionId: "sch_to_task"), // 달력->할일 변환
    MenuFunction(category: "비서", group: "일정", title: "시스템 달력 열기", icon: Icons.open_in_new, actionId: "app_calendar"), // 상세 확인용 바로가기

    // 1-2. 업무/할 일 (Task)
    MenuFunction(category: "비서", group: "업무", title: "오늘 일정 긴급 조정", icon: Icons.warning_amber, actionId: "task_emergency"),
    MenuFunction(category: "비서", group: "업무", title: "할 일 자동 정리", icon: Icons.task_alt, actionId: "task_auto"),
    MenuFunction(category: "비서", group: "업무", title: "업무 소요 시간 기록", icon: Icons.timer, actionId: "task_time_track"),
    MenuFunction(category: "비서", group: "업무", title: "오늘 업무 시간 통계", icon: Icons.bar_chart, actionId: "task_time_summary"),
    MenuFunction(category: "비서", group: "업무", title: "나만의 업무 원칙", icon: Icons.bookmark, actionId: "task_personal_rule"),
    MenuFunction(category: "비서", group: "업무", title: "일정 누락 감지", icon: Icons.error_outline, actionId: "task_schedule_check"), // 달력 vs 할일 비교
    MenuFunction(category: "비서", group: "업무", title: "미완료 업무 리마인드", icon: Icons.alarm, actionId: "task_remind"),
    MenuFunction(category: "비서", group: "업무", title: "우선순위 재정렬", icon: Icons.sort, actionId: "task_priority"),
    MenuFunction(category: "비서", group: "업무", title: "오늘의 마감 확인", icon: Icons.event_busy, actionId: "task_deadline"),

    // 1-3. 회의 및 음성 (Meeting & Voice)
    MenuFunction(category: "비서", group: "회의", title: "실시간 녹음/속기", icon: Icons.mic, actionId: "meet_record"),
    MenuFunction(category: "비서", group: "회의", title: "회의록 자동 완성", icon: Icons.edit_note, actionId: "meet_auto_write"),
    
    // [위치 기반 추천 유지] - 회의 맥락 파악 후 제안용
    MenuFunction(category: "비서", group: "회의", title: "회식/이벤트 장소 추천", icon: Icons.celebration, actionId: "meet_recommend_place"),
    
    MenuFunction(category: "비서", group: "회의", title: "회의 전 체크리스트", icon: Icons.fact_check, actionId: "meet_precheck"),
    MenuFunction(category: "비서", group: "회의", title: "회의 후 후속 정리", icon: Icons.assignment_turned_in, actionId: "meet_postcheck"),
    MenuFunction(category: "비서", group: "회의", title: "화자 분리(A/B)", icon: Icons.record_voice_over, actionId: "meet_diarization"),
    MenuFunction(category: "비서", group: "회의", title: "녹음 음질 개선", icon: Icons.graphic_eq, actionId: "meet_denoise"),
    MenuFunction(category: "비서", group: "회의", title: "안건(Agenda) 도출", icon: Icons.list_alt, actionId: "meet_agenda"),
    MenuFunction(category: "비서", group: "회의", title: "결과 공유하기", icon: Icons.share, actionId: "meet_share"),

    // 1-4. 문서 분석 (Analysis)
    MenuFunction(category: "비서", group: "분석", title: "3줄 핵심 요약", icon: Icons.short_text, actionId: "doc_summary"),
    MenuFunction(category: "비서", group: "분석", title: "계약서 독소조항", icon: Icons.warning_amber, actionId: "doc_risk"),
    MenuFunction(category: "비서", group: "분석", title: "다국어 번역", icon: Icons.translate, actionId: "doc_trans"),
    MenuFunction(category: "비서", group: "분석", title: "PDF 텍스트 추출", icon: Icons.picture_as_pdf, actionId: "doc_pdf_text"),
    MenuFunction(category: "비서", group: "분석", title: "맞춤법 검사", icon: Icons.spellcheck, actionId: "doc_spell"),

    // ==============================================================================
    // [탭 2] 현장 도구 (Mobile Tools)
    // ==============================================================================
    
    // (기존 유지: 즉시 실행, 오피스, 연동)
    MenuFunction(category: "도구", group: "즉시", title: "임시 파일 보관함", icon: Icons.folder_open, actionId: "quick_temp_files"),
    MenuFunction(category: "도구", group: "즉시", title: "통화 내용 메모", icon: Icons.call, actionId: "quick_call_memo"),
    MenuFunction(category: "도구", group: "즉시", title: "빠른 음성 메모", icon: Icons.mic_external_on, actionId: "quick_voice_memo"),
    MenuFunction(category: "도구", group: "즉시", title: "텍스트 빠른 메모", icon: Icons.edit, actionId: "quick_text_memo"),
    MenuFunction(category: "도구", group: "즉시", title: "최근 메모 모아보기", icon: Icons.notes, actionId: "quick_memo_list"),
    MenuFunction(category: "도구", group: "즉시", title: "클립보드 정리", icon: Icons.content_paste, actionId: "quick_clipboard"),
    MenuFunction(category: "도구", group: "즉시", title: "스크린샷 공유", icon: Icons.screenshot, actionId: "quick_screenshot"),

    MenuFunction(category: "도구", group: "오피스", title: "전자 서명 생성", icon: Icons.draw, actionId: "tool_sign"),
    MenuFunction(category: "도구", group: "오피스", title: "PDF 서명 날인", icon: Icons.approval, actionId: "tool_pdf_sign"),
    MenuFunction(category: "도구", group: "오피스", title: "문서 스캔 (OCR)", icon: Icons.document_scanner, actionId: "tool_ocr"),
    MenuFunction(category: "도구", group: "오피스", title: "명함 촬영 저장", icon: Icons.contact_mail, actionId: "tool_bizcard"),
    MenuFunction(category: "도구", group: "오피스", title: "영수증 스캔", icon: Icons.receipt_long, actionId: "tool_receipt"),
    MenuFunction(category: "도구", group: "오피스", title: "화이트보드 보정", icon: Icons.camera_indoor, actionId: "tool_whiteboard"),
    MenuFunction(category: "도구", group: "오피스", title: "계약서 돋보기", icon: Icons.zoom_in, actionId: "tool_magnifier"),
    MenuFunction(category: "도구", group: "오피스", title: "대본 프롬프터", icon: Icons.subtitles, actionId: "tool_prompter"),
    MenuFunction(category: "도구", group: "오피스", title: "이미지 모자이크", icon: Icons.blur_on, actionId: "tool_mosaic"),
    MenuFunction(category: "도구", group: "오피스", title: "가짜 전화(탈출)", icon: Icons.ring_volume, actionId: "tool_fake_call"),
    MenuFunction(category: "도구", group: "오피스", title: "발표 타이머", icon: Icons.timer, actionId: "tool_timer"),

    MenuFunction(category: "도구", group: "연동", title: "지도 실행", icon: Icons.map, actionId: "app_map"),
    MenuFunction(category: "도구", group: "연동", title: "택시 호출", icon: Icons.local_taxi, actionId: "app_taxi"),
    MenuFunction(category: "도구", group: "연동", title: "검색 포털", icon: Icons.search, actionId: "app_browser"),
  ];

  static List<MenuFunction> getFunctions(String mode) {
    if (mode == 'assistant') return assistantFunctions;
    return [];
  }
}