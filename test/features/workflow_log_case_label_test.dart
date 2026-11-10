import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/workflow_log/domain/workflow_log.dart";

WorkflowLogEntry _entry({String? caseId, String? caseTitle}) =>
    WorkflowLogEntry(
      id: "log-1",
      createdAt: "2026-11-10T00:00:00Z",
      componentCode: "SYSTEM",
      actorCode: null,
      eventCode: "GROUP_LINKED",
      caseId: caseId,
      caseTitle: caseTitle,
    );

void main() {
  test("a case without an identified item is not shown as 'no case'", () {
    expect(_entry(caseId: "case-1", caseTitle: "냉동망고").caseLabel, "냉동망고");
    expect(_entry(caseId: "case-1").caseLabel, "품목 미확인 업무");
    expect(_entry().caseLabel, "업무 없음 (접수 단계)");
  });
}
