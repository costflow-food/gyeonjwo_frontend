# 견줘 Flutter 프론트엔드

현재 서버 대신 비동기 프리뷰 응답을 사용하는 MVVM 구조입니다.

## 데이터 흐름

View → ViewModel → Repository → DataSource 순서로 요청하고, 응답은 반대 방향으로 전달합니다.

| 위치 | 책임 |
| --- | --- |
| `features/기능/data/*_preview_data.dart` | 가짜 API 응답 JSON |
| `features/기능/data/*_data_source.dart` | 비동기 응답 제공, 향후 실제 API 호출 |
| `features/기능/data/*_repository_impl.dart` | JSON 응답을 앱 모델로 변환 |
| `features/기능/domain/` | 앱 모델과 Repository 인터페이스 |
| `features/기능/presentation/*_view_model.dart` | Riverpod 상태, 조회·새로고침·검색·필터 |
| `features/기능/presentation/*_view.dart` | 로딩·오류·데이터에 따른 화면 표시 |
| `features/기능/presentation/widgets/` | 해당 기능의 화면 구성 요소 |
| `shared/widgets/` | 여러 기능이 사용하는 공용 위젯 |

`domain` 모델은 화면과 앱에서 사용하는 임시 데이터 계약이며, DB 테이블이나 ER 설계를 확정하는 모델은 아닙니다. 현재는 단순 조회이므로 별도의 UseCase는 두지 않습니다.

## 현재 동작

- 가짜 DataSource는 250ms 후 새 JSON 객체를 반환합니다. 실제 네트워크 요청은 없습니다.
- Repository가 응답을 `RequestItem`, `PurchaseReview`, `SupplierQuote`로 변환합니다.
- ViewModel은 `AsyncNotifier`로 로딩·오류·성공 상태를 관리합니다.
- 업무 큐는 서버 응답을 기준으로 건수를 집계하며 상태와 제목·거래처로 필터링합니다.
- 목록 새로고침과 오류 화면의 다시 시도는 DataSource를 다시 호출합니다.
- 실행·결과 보기 버튼은 선택한 요청 ID를 `/review?requestId=...`로 전달합니다.
- 상세 ViewModel은 요청 ID별로 분리되고 앱 실행 중 유지됩니다. 화면을 오가도 같은 요청의 결과를 재사용하며, 앱을 종료하거나 브라우저를 새로고침하면 사라집니다.
- 검토 예시는 공통 합성 수치를 사용합니다. 알 수 없는 요청 ID는 다른 요청의 결과로 대체하지 않고 오류로 처리합니다.
- 원문 보기·사유 보기·거래처 상세 근거 등 기존 시연 버튼의 후속 기능은 아직 구현하지 않았습니다.

## 실제 API 연결

1. 각 기능의 DataSource 인터페이스를 구현하는 실제 API 클래스를 추가합니다.
2. `workQueueDataSourceProvider`, `purchaseReviewDataSourceProvider`가 실제 API 구현을 반환하도록 바꿉니다.
3. 응답 형식이 달라지면 Repository의 변환 코드와 필요한 앱 모델을 수정합니다.

상태 관리와 화면은 DataSource 구현을 직접 참조하지 않으므로, 앱 모델이 유지되는 한 수정할 필요가 없습니다. DB 접근 방식과 인증은 서버 계약 확정 후 연결합니다.

## 실행 및 검증

```sh
flutter run -d chrome
flutter analyze
flutter test
```

기존 반응형 화면 테스트에 더해 로딩 대기, 검색·상태 필터 조합, 오류 후 재시도, 요청별 결과 유지, 선택한 요청의 상세 이동을 검증하는 테스트가 있습니다.
