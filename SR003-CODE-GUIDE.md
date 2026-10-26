# SR003 수정 코드

수정한 화면 구현 코드는 `lib/widgets/sr003/`에 실제로 모아 두었습니다.
앱의 기존 View가 이 위젯 파일들을 import해서 사용합니다.

## review_progress/
- review_progress_dialog.dart: 검토 진행 팝업 전체 배치
- review_progress_header.dart: 제목과 닫기 버튼
- review_progress_body.dart: 안내 문구와 진행 단계 목록
- review_progress_step.dart: 단계 한 줄
- review_progress_footer.dart: 검토 결과 보기 버튼

## purchase_review/
- purchase_review_content.dart: 검토 결과 본문과 카드 배치

상태 로직은 `lib/features/review_progress/presentation/review_progress_view_model.dart`에 유지합니다.
기존 데이터 연결과 업무 큐 수정 코드는 해당 features 폴더에 유지합니다.
`SR003-review.code-workspace`를 열면 수정한 화면 코드가 첫 번째 폴더로 표시됩니다.
거래처 관리 페이지 작업은 취소했습니다.
