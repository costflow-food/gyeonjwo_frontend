# SCR-003 코드 위치

- `lib/features/review_progress/presentation/review_progress_view.dart`: showDialog 진입점과 상태 구독
- `lib/features/review_progress/presentation/review_progress_view_model.dart`: 요청별 비동기 조회 상태
- `lib/features/review_progress/presentation/widgets/`: 진행 팝업의 헤더·본문·하단 버튼
- `lib/features/purchase_review/presentation/widgets/purchase_review_content.dart`: 검토 결과 본문
- `lib/features/work_queue/domain/work_queue_state.dart`: 진행 상태와 요청 목록을 조합하는 규칙, 검색·필터

기능 전용 위젯은 각 Feature의 `presentation/widgets`에 둡니다. 공용 위젯은 `lib/shared/widgets`에 둡니다.
진행 창은 상세 결과의 비동기 조회를 기다리며, 로컬 타이머로 분석 단계를 만들지 않습니다.
