# 검토 대화상자 PR 통합 기록

통합 브랜치: `integration/review-dialogs`

기준 브랜치: `origin/Presentaion_widgets` (`84974bc`)

## 포함한 PR

| PR | 기능 | 통합한 원본 커밋 |
| --- | --- | --- |
| [검토 진행 화면 및 위젯 분리](https://github.com/costflow-food/gyeonjwo_frontend/pull/8) | SCR-003 | `82cceaa` |
| [원문·근거 보기 팝업](https://github.com/costflow-food/gyeonjwo_frontend/pull/6) | SCR-004 | `30f6299` |
| [분석 중단 사유 대화상자](https://github.com/costflow-food/gyeonjwo_frontend/pull/7) | SCR-006 | `1b637b5` |

원본 PR의 커밋을 merge commit으로 보존했습니다. 원격 대상 브랜치와 원본 PR에는 변경을 적용하지 않았습니다.

## 충돌 해결

- `lib/features/purchase_review/presentation/purchase_review_view.dart`: SCR-003이 본문을 분리한 구조를 유지했습니다. SCR-004가 추가한 원문 버튼 동작은 실제 본문이 위치한 `lib/widgets/sr003/purchase_review/purchase_review_content.dart`로 옮겼습니다.
- `lib/features/work_queue/presentation/widgets/request_row.dart`: 실행·진행 보기는 검토 진행 경로로, 결과 보기는 검토 결과 경로로, 사유 보기는 분석 중단 창으로 연결했습니다. 문서 영역과 원문 보기 버튼의 원문 팝업 동작도 유지했습니다.
- SCR-006의 원문 확인 callback에 SCR-004를 연결해 동일한 요청 ID가 전달되도록 했습니다. 준비되지 않은 원문은 다른 요청으로 대체하지 않습니다.
- 원문 확인을 비활성으로 기대하던 SCR-006 테스트를 실제 연결 흐름에 맞게 갱신했습니다.

## 검증

- `flutter analyze --no-pub`: 문제 없음.
- `flutter test --no-pub --reporter expanded`: 50개 통과.
- 진행 중인 요청의 원문을 열어도 진행이 유지되고, 완료 후 같은 요청의 결과와 원문을 확인하는 통합 테스트를 추가했습니다.
- 중단 사유의 원문 확인에서 준비되지 않은 원문을 안내하고 업무 큐로 복귀하는 흐름을 확인했습니다.
- 기존 작은 화면·확대 글자·상태 유지·재시도 테스트도 모두 통과했습니다.

## 현재 범위

진행 상태와 문서는 각 PR의 합성 프리뷰 데이터를 사용합니다. 실제 분석 중단 이벤트를 검토 진행 창에 전달하는 서버 API는 이번 PR들에 구현되어 있지 않아 새로 만들지 않았습니다. 거래처 상세 근거(SCR-005)는 이번 세 PR의 범위에 포함되지 않습니다.

SCR-006 원본 PR에서 제기한 업무 큐의 중단 사유 재진입 정책은 별도 기획 확인 사항입니다. 이번 통합에서는 원본 PR이 제공한 사유 보기 경로를 유지했습니다.
