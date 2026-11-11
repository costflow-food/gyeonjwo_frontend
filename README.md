# 견줘 Flutter 프론트엔드

견줘 서버 API를 쓰는 Flutter Web 앱입니다. Chrome을 기준으로 개발·검증합니다.

## 실행

`config/dart_defines.example.json`을 복사해 `config/dart_defines.local.json`을 만들고 값을 채웁니다. `*.local.json`은 Git에 올리지 않습니다.

| 키 | 값 |
| --- | --- |
| `SUPABASE_URL` | Supabase 프로젝트 주소 |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable 키 |
| `API_BASE_URL` | 견줘 API 서버 주소 |

```sh
flutter pub get
flutter run -d chrome --dart-define-from-file=config/dart_defines.local.json
flutter analyze
```

공개해도 되는 값만 넣습니다(`lib/app/app_config.dart`). 값이 빠지면 앱은 실행 설정 안내 화면을 띄웁니다.

## 폴더 구조

```
lib/
  main.dart        앱 시작, Supabase 초기화, 테마 적용
  app/             설정값(app_config), 라우팅(app_router), 없는 경로 화면
  features/        기능별 data / domain / presentation
  shared/          여러 기능이 함께 쓰는 코드
```

### features

| 폴더 | 내용 |
| --- | --- |
| `auth` | Google 로그인, Gmail 연결, 설정 화면(`/account`) |
| `work_queue` | 업무 큐(`/`, `/cases/:caseId`), 원문·첨부, 후보 선택 |
| `review_progress` | 검토 진행 팝업 |
| `purchase_review` | 검토 카드(`/cases/:caseId/review`) |
| `mail_draft` | 메일 초안·발송 모달 |
| `send_settings` | 발송·메일 스타일 설정 모달 |
| `mail_intake` | 접수·연결 확인 모달 |
| `supplier` | 거래처 조회(`/suppliers`)와 근거·가격 이력 모달 |
| `source_document` | 원문·근거 보기 모달 |
| `workflow_log` | 실행 로그(`/logs`) |
| `server_status` | 서버 준비 상태(`GET /ready`) |

각 기능은 View → ViewModel → Repository → DataSource 순서로 요청합니다.

| 위치 | 책임 |
| --- | --- |
| `data/*_data_source.dart` | API 호출 |
| `data/*_repository_impl.dart` | JSON 응답을 앱 모델로 변환 |
| `domain/` | 앱 모델, Repository 인터페이스, 화면 규칙 |
| `presentation/*_view_model.dart` | Riverpod 상태 |
| `presentation/*_view.dart`, `*_dialog.dart` | 화면과 모달 |
| `presentation/widgets/` | 해당 기능 전용 위젯 |

### shared

| 위치 | 내용 |
| --- | --- |
| `network/` | 공용 Dio 클라이언트, 인증 GET 요청 |
| `theme/` | 테마·다크 모드 선택 상태와 설정 화면의 테마 선택기 |
| `widgets/` | 앱 틀(사이드바·셸)과 공용 위젯, 버튼 스타일 |
| `workspace_colors.dart` | 테마 팔레트와 다크 버전 |
| `app_font_sizes.dart` | 글자 크기 단계 |
| `formatters.dart`, `idempotency_key.dart` | 숫자·날짜 표시, 멱등 키 |
| `file_save/`, `navigation/` | 웹 전용 파일 다운로드·브라우저 주소 이동(다른 플랫폼에서는 `UnsupportedError`) |

## 테마

`shared/workspace_colors.dart`에 팔레트가 있고, 목록의 첫 번째가 기본값입니다. 다크 모드는 고른 팔레트에서 다크 버전을 만들어 씁니다. 설정 화면(`/account`)의 "화면 테마" 탭에서 고르며, 고른 값은 브라우저에 저장됩니다.

## Provider 코드 생성

Provider는 `@Riverpod`로 선언합니다. 선언이나 `build` 인자를 바꾸면 다시 생성합니다.

```sh
dart run build_runner build
```

`*.g.dart`는 직접 고치지 않고, 소스와 함께 커밋합니다.

## 테스트

`test/`는 `.gitignore`에 들어 있지만 일부 테스트 파일은 저장소에 포함돼 있습니다.

```sh
flutter test
```

## 배포

`.github/workflows/deploy-web.yml`이 `dev` → `main` PR이 머지되면 `flutter build web --release`로 빌드해 Vercel 프로덕션에 올립니다. Vercel은 GitHub 저장소와 연결하지 않고 이 워크플로만 배포합니다. 필요한 값은 저장소 Actions 설정에 둡니다.

- Secrets: `VERCEL_TOKEN`
- Variables: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `API_BASE_URL`(https), `VERCEL_PROJECT`(선택)
