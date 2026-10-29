# 견줘 Flutter 프론트엔드

현재 서버 대신 비동기 프리뷰 응답을 사용하는 MVVM 구조입니다.

## 개발 대상

Chrome에서 실행하는 Flutter Web을 기준으로 개발·검증합니다. 실행은 `flutter run -d chrome`, 배포용 빌드는 `flutter build web --release`를 사용합니다.

사용하지 않는 `android/`, `ios/`, `macos/`, `windows/` 네이티브 프로젝트를 정리했습니다. `web/`은 버전 관리하며, 테스트 소스인 `test/`는 로컬에 보관하고 Git 추적에서 제외합니다. React 비교 구현은 `feature/react-frontend` 브랜치에 보관하며, 로컬에 남는 React 의존성과 빌드·테스트 생성물은 공용 `.gitignore`로 제외합니다.

## UI 확인용 임시 경로

`flutter run -d chrome`으로 실행한 뒤 주소 끝에 `/#/ui-preview`를 입력합니다. 코드 추가 직후에는 Hot Restart가 필요합니다. 이 경로는 Debug 빌드에만 등록되며 Profile·Release에는 제공하지 않습니다.

- 기본 화면: 업무 큐, 구매 검토, 실행 로그, 거래처, 로그인, 권한 안내, Gmail 연결 상태, 계정 설정.
- 모달: 원문·첨부, 검토 진행, 확인 필요, 거래처·가격 근거, 메일 초안·발송, 메일함/업무별 발송 설정, 접수·연결 확인.
- 상단 **화면 목록**으로 돌아가고 **시연 초기화**로 샘플 데이터·선택·진행 상태를 처음 상태로 되돌립니다.
- 별도 ProviderContainer와 라우터에서 합성 데이터를 사용합니다. 기존 로그인 세션을 사용하지 않으며 실제 로그인·메일 발송을 실행하지 않습니다. 기존 사이드 메뉴와 모달 이동도 프리뷰 안에서 동작합니다.

특정 화면이나 모달을 바로 열려면 다음 주소를 사용합니다. `?`는 `#` 뒤에 들어갑니다.

| 주소 끝부분 | 내용 |
| --- | --- |
| `/#/ui-preview` | 화면·모달 목록 |
| `/#/ui-preview?screen=queue` | 업무 큐 |
| `/#/ui-preview?screen=review` | 구매 검토 |
| `/#/ui-preview?screen=logs` | 실행 로그 |
| `/#/ui-preview?screen=suppliers` | 거래처 |
| `/#/ui-preview?screen=mail-draft` | 메일 초안 모달 |
| `/#/ui-preview?screen=mail-draft&draftId=draft-d-clar-1` | 발송 확인 중 초안 |
| `/#/ui-preview?screen=send-settings` | 메일함 발송 설정 모달 |
| `/#/ui-preview?screen=case-settings` | 업무별 발송 설정 모달 |
| `/#/ui-preview?screen=intake` | 접수·연결 확인 모달 |
| `/#/ui-preview?screen=connection&state=sendDenied` | 발송 권한 거부 상태 |

추가 `screen` 값은 `source`, `progress`, `needs-info`, `supplier-evidence`, `login`, `permissions`, `account`입니다. 화면 안에서 이동해도 브라우저 주소는 진입 주소를 유지합니다. 다른 화면으로 바로 재진입하려면 위 주소를 사용합니다.

개발용 코드는 `lib/app/ui_preview.dart`에 모았고 일반 화면 위젯을 재사용합니다. 로컬 회귀 검사는 `flutter test test/ui_preview_test.dart`로 실행합니다.

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
- 실행·진행 보기·다시 시도는 `showReviewProgressDialog()`로 현재 화면 위에 진행 창을 엽니다. 원문·중단 사유도 `showDialog()`를 사용합니다. 진행 창용 경로와 업무 큐 배경 재생성은 없습니다.
- 진행 ViewModel은 기존 상세 결과 조회 `Future`를 기다립니다. 결과 조회가 성공해야 완료되고, 실패하면 오류와 수동 재시도를 제공합니다. 2초 간격의 가짜 단계 타이머는 사용하지 않습니다.
- 진행 창을 닫아도 요청별 조회와 결과 캐시는 유지됩니다. 결과 보기 버튼은 팝업을 닫고 같은 요청의 `/review?requestId=...`로 이동합니다.
- 업무 큐 ViewModel은 진행 상태를 구독하고 `domain/work_queue_state.dart`의 규칙으로 요청 상태·버튼·건수·검색·필터를 구성합니다. View는 완성된 상태를 표시합니다.
- 목록 원본은 `workQueueRequestsProvider`가 보관하므로 진행 상태 변화가 목록 API 재호출을 일으키지 않습니다. 새로고침은 목록을 다시 조회하며 검색·필터와 진행 상태를 유지합니다.
- 상세 ViewModel은 요청 ID별로 분리되고 앱 실행 중 유지됩니다. 화면을 오가도 같은 요청의 결과를 재사용하며, 앱을 종료하거나 브라우저를 새로고침하면 사라집니다.
- 검토 예시는 공통 합성 수치를 사용합니다. 알 수 없는 요청 ID는 다른 요청의 결과로 대체하지 않고 오류로 처리합니다.
- SCR-004 원문·근거 보기는 `features/source_document/`에 구현되어 있습니다. 업무 큐의 문서 영역·원문 보기와 검토 화면의 요청 원문 보기에서 열립니다.
- 원문은 요청 ID별로 조회합니다. 첫 번째 단가변경 요청과 뉴스레터의 합성 본문을 제공하며, 나머지는 준비되지 않았다는 안내를 표시합니다. 첨부파일은 합성 파일명만 표시합니다.
- 업무 큐의 사유 보기는 SCR-006 분석 중단 사유 창을 엽니다. 원문 확인을 누르면 같은 요청 ID의 SCR-004 팝업으로 이어집니다. 원문이 준비되지 않은 요청은 안내와 재시도를 표시합니다.
- SCR-011 거래처 조회는 `/suppliers`(사이드 메뉴 "거래처")이며 `features/supplier/`에 있습니다. 06 스키마의 suppliers·supplier_items와 08 API-29·30을 기준으로 검색·이름순 목록·상세(업체 정보·취급 품목·인증·비고·기준자료 출처)를 보여줍니다.
- 거래처 화면은 조회 전용입니다. 등록 진입은 제공하지 않으며 등록 관련 코드는 후속 범위 검토를 위해 보존합니다. 좁은 창에서는 거래처를 선택하면 상세로 이동하고 "목록으로" 버튼으로 검색·목록에 돌아갑니다.
- 품목의 "근거·가격 이력"은 SCR-005 거래처·견적 근거 모달을 엽니다. API-31 형식으로 참고 견적(메일)과 실거래(증빙)를 나눠 표시하고, 원문 메일이 있으면 SCR-004를 위에 엽니다. 업무별 체크리스트·현재 견적 조건은 업무 상세 맥락에서 연결할 대상입니다.
- 근거 모달은 가격 이력·출처를 먼저 표시하고, 중복되는 업체·품목 상세는 접어서 제공합니다. 거래처 데이터는 현재 합성 Preview DataSource이며 실제 API 연결은 후속 작업입니다.
- SCR-010 실행 로그는 `/logs`(사이드 메뉴 "실행 로그")이며 `features/workflow_log/`에 있습니다. API-28 형식으로 업무·기간·역할/노드·이벤트·결과·발송 방식을 필터링하고, 상세에서 근거·견적/설정 버전·도구 결과 참조·request_id와 관련 업무·원문·초안으로 이동합니다.
- SCR-007 메일 초안·발송 모달은 `features/mail_draft/`에 있고 업무 상세의 "메일 초안"과 실행 로그의 "초안 보기"에서 엽니다. 업체별 초안 상태를 따로 보여주며, 승인 ON은 "승인 후 발송", 승인 OFF는 승인 버튼 없이 자동 발송 범위와 결과만 표시합니다. 수정은 새 초안(API-18)이고, 발송 확인 중(UNKNOWN)은 수정·재발송을 막고 발신함 대조(API-20)만 제공합니다.
- SCR-008 발송·메일 스타일 설정 모달은 `features/send_settings/`에 있고 업무 큐의 "발송 설정"(메일함 기본값)과 메일 초안 모달의 "발송 설정"(업무 설정)에서 엽니다. 목적별 승인은 미설정/ON/OFF 중 고르며 기본값을 임의로 채우지 않습니다. 적용 대상은 앞으로 생성할 초안 또는 선택한 기존 초안이고, 발송 중·발송됨·확인 중 초안은 고를 수 없습니다.
- SCR-009 접수·연결 확인 모달은 `features/mail_intake/`에 있고 업무 큐의 "접수 확인 n건"에서 엽니다(대기 메일이 없으면 버튼을 숨깁니다). 비업무로 확인·새 업무로 접수·선택한 업무에 연결 중 하나를 고르며, 새 업무는 대기 상태로만 만들고 분석을 시작하지 않습니다.
- 네 기능과 업무 큐·접수 원문은 `shared/preview_workspace.dart`의 세션 데이터를 공유합니다. 업무별 설정 저장은 메일함 기본값을 바꾸지 않으며, 선택한 기존 초안의 설정·자동 발송 결과와 새 접수 업무의 대기 행이 화면 간에 이어집니다. 기존 초안 적용은 현재 DRAFT에만 허용하고 SENDING·SENT·UNKNOWN은 변경하지 않습니다.
- 새 업무 접수는 큐에 대기 행과 원문만 추가하며 분석을 시작하지 않습니다. 접수 목록과 업무 큐를 함께 갱신합니다.
- 발송 설정은 목적별 승인과 자동 발송 대상을 우선 표시하고 문안·서명·기존 초안 적용은 펼쳐서 편집합니다. 실행 로그는 업무·기간을 기본 필터로, 나머지는 상세 필터로 제공합니다. 좁은 창의 로그·접수 항목 선택은 상세로 스크롤하고 "목록으로"로 복귀합니다.
- 새 모달의 버튼은 `shared/widgets/workspace_button_styles.dart`로 기존 모서리·색·글자 크기를 공유하며, 비활성·처리 중 동작은 각 버튼에 유지합니다.
- 프리뷰 변경은 메모리에만 남고 브라우저 새로고침 시 초기화됩니다. 실제 메일은 발송하지 않으며, 유효 설정·허용 업체/등록 수신자 범위 안의 자동 발송만 약 2초 후 SENT로 바뀝니다. 발송 모달에 시연임을 표시합니다.

## 폴더와 상태 컨벤션

- 기능 전용 UI는 `features/기능/presentation/widgets/`에 둡니다. 구매 검토 본문과 진행 팝업도 이 기준을 따릅니다.
- 공용 UI는 `shared/widgets/`에 둡니다. 화면 번호별로 기능 코드를 별도 분류하지 않습니다.
- Provider는 `@Riverpod` 코드 생성으로 선언합니다. 진행 상태도 요청 ID별 Provider이며 `keepAlive: true`로 유지합니다.
- Notifier는 조회와 상태 갱신을 조정하고, 검색·필터·요청 상태 조합 규칙은 domain에서 처리합니다.
- 현재 진행 창은 합성 상세 응답의 조회 완료를 표시합니다. 실제 서버의 단계별 분석 진행·분석 중단 이벤트는 해당 API가 정해진 뒤 연결합니다.

## 인증·Gmail 연결

인증·Gmail 연결은 **KAN-19 프론트 작업 완료, 서버 연동 대기** 상태입니다. Supabase Auth Google 로그인과 Gmail 연결 코드는 `features/auth/`에 있습니다. 실행 설정, 흐름, 서버 연결 계약은 `docs/auth-ui.md`를 참고하세요. Supabase 설정 없이 실행하면 기존 화면 미리보기 모드로 동작합니다.

## 실제 API 연결

1. 각 기능의 DataSource 인터페이스를 구현하는 실제 API 클래스를 추가합니다.
2. `workQueueDataSourceProvider`, `purchaseReviewDataSourceProvider`가 실제 API 구현을 반환하도록 바꿉니다.
3. 응답 형식이 달라지면 Repository의 변환 코드와 필요한 앱 모델을 수정합니다.

상태 관리와 화면은 DataSource 구현을 직접 참조하지 않으므로, 앱 모델이 유지되는 한 수정할 필요가 없습니다. DB 접근 방식과 인증은 서버 계약 확정 후 연결합니다.

## Provider 코드 생성

Provider는 `@Riverpod` 어노테이션으로 선언합니다. 함수는 의존성을 제공하고,
ViewModel 클래스는 `_$WorkQueueViewModel` 같은 생성 클래스를 상속합니다.
기존 Provider 이름과 `ref.watch` / `ref.read` 사용법은 유지합니다.

`@Riverpod(keepAlive: true)`는 화면을 나가도 상태가 유지되도록 하는 설정입니다.
기본 `@riverpod`는 자동 폐기되므로 기존 수명을 보존하려고 이 설정을 사용했습니다.
상세의 `build(String requestId)` 인자로 요청별 Provider가 생성됩니다.
ViewModel의 `retry: _noRetry`는 자동 재시도를 끄며, 버튼의 수동 재조회는 유지합니다.

선언이나 `build` 인자를 바꾼 뒤 앱 폴더에서 다시 생성하세요.

```sh
dart run build_runner build
```

`part '*.g.dart'`로 연결된 생성 파일은 직접 수정하지 않습니다.
저장소 방침에 따라 생성 파일도 소스와 함께 버전 관리합니다.

## 실행 및 검증

```sh
flutter run -d chrome
flutter analyze
flutter test  # 로컬 test/ 폴더가 있는 환경에서 실행
```

기존 반응형 화면 테스트에 더해 로딩 대기, 검색·상태 필터 조합, 오류 후 재시도, 요청별 결과 유지, 선택한 요청의 상세 이동을 검증하는 테스트가 있습니다.
