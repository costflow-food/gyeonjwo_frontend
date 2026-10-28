# 인증 화면 미리보기

현재 실행 시작 화면은 `/login`입니다. 기존 업무 큐(`/`)와 구매 검토(`/review`)는 유지합니다.

| 경로 | 화면 |
| --- | --- |
| `/login` | Google 가입·로그인 진입 |
| `/login/permissions` | 계정·Gmail 권한과 데이터 처리 안내 |
| `/login/connection` | 연결 상태 미리보기 |
| `/account` | 계정 설정·Gmail 연결 정보·로그아웃 |

Google로 계속하기 → 권한 안내 → 연결 상태 순서로 화면만 이동합니다. Google 계정 선택·권한 동의 화면을 흉내 내거나 실제 동의를 저장하지 않습니다.

연결 화면 아래의 칩으로 연결 중, 성공, 읽기 거부, 발송 거부, 읽기·발송 거부, 실패, 재연결 상태를 확인할 수 있습니다. `?state=connected`, `readDenied`, `sendDenied`, `bothDenied`, `failed`, `reconnect`, `connecting`으로 직접 열 수도 있습니다. 누락되거나 알 수 없는 값은 연결 중 예시로 표시됩니다. 시간 경과로 성공 상태로 바뀌지는 않습니다.

권한별 사용 가능 표시는 UI 예시입니다. 실제 메일 기능이나 업무 큐의 접근 권한을 변경하지 않습니다. 업무 큐 미리보기는 기존 합성 데이터 화면을 엽니다. 계정·토큰·동의 상태는 저장하지 않으며, Supabase 초기화나 네트워크 요청은 추가하지 않았습니다.

다음 단계에서 Supabase Auth Google OAuth, `gmail.readonly`·`gmail.send`와 오프라인 접근, 세션·리디렉션, 서버 연결 계약을 붙입니다. 실제 외부 LLM 제공업체와 전송 데이터 범위를 확정한 뒤 동의 전 안내에 반영해야 합니다. 현재 안내에는 미확정 상태를 명시했습니다. 실제 메일 발송 승인 설정은 Gmail 발송 권한과 별도로 구현합니다.

```sh
flutter run -d chrome
```

사이드바 하단 사용자 영역에서 계정 설정으로 이동합니다. 사이드바가 접힌 경우에도 계정·로그아웃 아이콘을 표시합니다. 로그아웃 버튼은 미리보기에서 `/login`으로 돌아가기만 하며, 실제 Supabase 세션 종료와 데이터 정리는 인증 기능 연결 시 추가합니다.

Google 진입 버튼은 `presentation/widgets/google_sign_in_button.dart`에서 공식 다색 G 로고와 밝은 테마 기준을 사용합니다. 자산 출처와 규격은 `assets/branding/google/README.md`를 참고하세요. 클릭 시 권한 안내로 이동하는 기존 미리보기 동작을 유지합니다.
