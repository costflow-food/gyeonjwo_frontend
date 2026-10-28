# 인증·Gmail 연결

## 작업 상태

**KAN-19: 프론트 작업 완료, 서버 연동 대기.**

Supabase Google 가입·로그인, Gmail 권한 요청과 동의 전 안내, 토큰 전달·연결 상태 표시 코드, 라우트 가드와 로그아웃을 구현했습니다. 부분 거부 처리와 토큰 전달·상태 표시는 코드 및 테스트로 검증하는 범위입니다.

KAN-17 서버 연결 API가 준비되면 `API_BASE_URL`과 계약을 확인하고, 테스트 사용자가 가입·동의한 뒤 Gmail 자동 수신을 시작하는 전체 흐름을 실제 서버 응답으로 검증해야 합니다. 현재 Gmail 자동 수신까지의 통합 완료를 의미하지 않습니다.

동의 안내의 외부 LLM 제공업체와 전달 데이터 범위는 **확정 전**으로 남아 있습니다. 실제 외부 LLM 연결 전 문구를 확정해야 합니다.

Flutter Web에서 Supabase Auth로 Google 가입·로그인을 하고, 같은 Google 동의 화면에서 `gmail.readonly`·`gmail.send`와 오프라인 접근을 요청합니다. 인증 직후 받은 Google 토큰은 HTTPS로 견줘 서버에 전달하고, 서버의 연결 결과를 기다려 화면에 표시합니다.

## 실행

```sh
cp config/dart_defines.example.json config/dart_defines.local.json   # 값 채우기, Git 제외
dart run build_runner build -d
flutter run -d chrome --web-port 3000 --dart-define-from-file=config/dart_defines.local.json
```

| 키 | 설명 |
| --- | --- |
| `SUPABASE_URL` | Supabase 프로젝트 URL |
| `SUPABASE_PUBLISHABLE_KEY` | 공개 키(`sb_publishable_...`). 서버 전용 키는 넣지 않습니다 |
| `API_BASE_URL` | 견줘 API 주소. HTTPS만 허용하며 `localhost`·`127.0.0.1`만 예외입니다 |

`SUPABASE_URL`·`SUPABASE_PUBLISHABLE_KEY` 없이 실행하면 기존 화면 미리보기 모드로 동작합니다. 라우트 가드가 꺼지고 `/login/connection?state=connected|readDenied|sendDenied|bothDenied|failed|reconnect|connecting` 칩 미리보기를 사용할 수 있습니다. 위젯 테스트도 이 모드로 실행됩니다.

### 외부 설정 (대시보드)

- Google Cloud: Gmail API 사용 설정, OAuth 동의 화면에 두 Gmail 범위와 테스트 사용자 추가, 웹 클라이언트의 승인된 리디렉션 URI에 `https://<project-ref>.supabase.co/auth/v1/callback` 등록.
- Supabase Auth: Google provider 사용 설정(클라이언트 ID·시크릿), URL Configuration의 Redirect URLs에 `http://localhost:3000/`와 배포 주소 등록.
- 동의 화면이 "테스트" 상태면 Google refresh token이 7일 후 만료됩니다.

## 흐름

1. `/login` → Google로 계속하기 → `/login/permissions`에서 로그인·메일 읽기·발송·외부 LLM 처리 목적을 안내합니다.
2. Google로 계속하기 → `signInWithOAuth(google, scopes: gmail.readonly gmail.send, access_type=offline, prompt=consent)`. 계정 선택과 권한 동의는 Google 화면에서 사용자가 진행합니다.
3. Google → Supabase → 앱 루트로 돌아오면 Supabase가 세션을 만들고 라우트 가드가 `/login/connection`으로 보냅니다.
4. `GmailConnectionViewModel`이 이 페이지의 `provider_token`·`provider_refresh_token`을 서버에 한 번 보내고 결과를 기다립니다.
5. 서버 응답의 `capabilities`로 연결 성공·읽기 거부·발송 거부·둘 다 거부·실패·재연결 필요를 표시합니다. 읽기가 거부되면 업무 큐에 안내가 표시됩니다. 발송 화면은 아직 없어 `gmailCapabilitiesProvider.canSend`만 준비해 두었습니다.

로그아웃은 Supabase 세션만 종료하며 서버의 Gmail 연결은 해제하지 않습니다.

## 프론트와 서버의 책임

화면 제한은 편의 기능입니다. 사용자 식별·권한 판정·기능 허용은 서버가 합니다.

| 프론트 | 서버 |
| --- | --- |
| 동의 전 안내, OAuth 시작 | Supabase JWT 검증으로 사용자 확정(본문의 사용자 정보는 사용하지 않음) |
| 리디렉션 직후 토큰을 HTTPS로 전달, 결과 대기 | Google tokeninfo로 발급 대상(`aud`)이 우리 클라이언트인지, 같은 Google 계정인지, 실제 허용 범위 확인 |
| 서버 결과로 상태 표시, 거부 기능 비활성화 | refresh token 암호화 보관·갱신 검증, 읽기 허용 시 watch·최초 동기화 |
| 토큰 저장·로그 금지 | 모든 메일 API에서 권한 재검사, 토큰을 로그·오류 응답에 남기지 않음 |

### 토큰 취급

- Supabase 기본 저장소는 세션 전체(`provider_token` 포함)를 localStorage에 저장합니다. `ProviderTokenFreeLocalStorage`가 Google 토큰을 제거하고 저장합니다. 토큰은 메모리에만 있다가 서버가 받으면 다시 보내지 않습니다.
- 새로고침 등으로 토큰을 보내기 전에 잃으면 서버 상태를 조회하고, 연결이 없으면 재연결을 안내합니다.
- `debug: false`로 Supabase 로그를 끄고 Dio 로그 인터셉터를 붙이지 않습니다. `Session`·응답 본문을 `print`하지 마세요.

## 서버 연결 계약 (초안 · KAN-17과 확정 필요)

경로는 `lib/features/auth/data/account_connection_data_source.dart`의 `AccountConnectionPaths`에 있습니다.

```http
POST /api/v1/mailboxes/google/connect
Authorization: Bearer {supabase access_token}
Idempotency-Key: {32 hex}
Content-Type: application/json

{"provider_access_token": "...", "provider_refresh_token": "..." | null}
```

```http
GET /api/v1/mailboxes/google/connection
Authorization: Bearer {supabase access_token}
```

두 응답 모두 08 공통 형식입니다.

```json
{
  "data": {
    "mailbox_ref": "...",
    "email": "buyer@example.com",
    "status": "CONNECTED | PARTIAL | NEEDS_RECONNECT | FAILED | NOT_CONNECTED",
    "capabilities": {"read": true, "send": false},
    "watch": {"started": true, "expiration": "2026-11-04T00:00:00Z"}
  },
  "meta": {"request_id": "..."}
}
```

- 오류는 `{"error": {"code": "...", ...}}`. 401은 재연결, 5xx·429·네트워크 오류·`409 REQUEST_IN_PROGRESS`는 같은 Idempotency-Key로 재시도, 그 밖의 4xx는 다시 동의를 받습니다.
- 같은 키·같은 본문은 최초 결과를 재사용해야 합니다(08 멱등성 규칙).
- refresh token이 없으면 `NEEDS_RECONNECT`를 반환합니다.
