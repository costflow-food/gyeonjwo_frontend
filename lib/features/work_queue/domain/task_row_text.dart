import "case_stage.dart";
import "work_case.dart";

// Tasks 한 줄형 행의 글자 (`docs/design-ssot.md` 7.13).
// [거래처 | 요청 유형 · 구분 | 상태 라벨 | 진행도 n/5]

/// 거래처 칸. API-01 `title`은 등록 거래처 이름(없으면 보낸 사람 주소)입니다.
/// 등록 거래처가 없고 견적 요청을 2곳 이상에 보냈으면 '후보 N곳'.
/// 견적 요청 전 후보 수는 목록 API에 없어 보여 줄 수 없습니다.
String taskPartyOf(WorkCase workCase) {
  final registered = !workCase.title.contains("@");
  final requested = workCase.replySummary?.requested ?? 0;
  if (!registered && requested >= 2) return "후보 $requested곳";
  if (registered) return workCase.title;
  return workCase.senderName ?? workCase.title;
}

/// 요청 유형 · 구분 칸. 목록 API에 메일 제목이 없어(백엔드 요청) 지금은
/// 단계 문구를 씁니다. 제목이 오면 [requestTypeOf]로 바꿉니다.
String taskDetailOf(WorkCase workCase) {
  final message = workCase.stepMessage.trim();
  return message.isNotEmpty
      ? message
      : processingStepLabel(
          workCase.processingStep,
          inputRevision: workCase.inputRevision,
        );
}

/// 메일 제목에서 '요청 유형 · 구분'을 뽑는 임시 규칙: `[머리말]`이 유형,
/// 나머지가 구분. 머리말이 없으면 제목 그대로입니다.
/// 예: "[단가변경] 냉동 딸기 1kg 단가 조정" → "단가변경 · 냉동 딸기 1kg 단가 조정".
String requestTypeOf(String subject) {
  final match = RegExp(r"^\s*\[([^\]]+)\]\s*(.*)$").firstMatch(subject);
  if (match == null) return subject.trim();
  final type = match.group(1)!.trim();
  final rest = match.group(2)!.trim();
  return rest.isEmpty ? type : "$type · $rest";
}

/// 진행도 칸 글자. 단계를 모르면 빈 글자입니다.
String taskProgressText(int? progress) =>
    progress == null ? "" : "$progress/${CaseStage.total}";
