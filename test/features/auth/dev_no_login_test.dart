import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/app/app_config.dart";
import "package:gyeonjwo_frontend/features/auth/data/dev_no_login_session_data_source.dart";
import "package:gyeonjwo_frontend/features/auth/domain/auth_route_policy.dart";

void main() {
  test("login is on unless the DEV build turns it off", () {
    expect(AppConfig.loginDisabled, isFalse);
  });

  test("login addresses go to the main page in the DEV zone", () {
    expect(noLoginRedirect("/login"), "/");
    expect(noLoginRedirect("/login/connection"), "/");
    expect(noLoginRedirect("/login/permissions"), "/");
    expect(noLoginRedirect("/"), isNull);
    expect(noLoginRedirect("/tasks/x"), isNull);
    expect(noLoginRedirect("/loginx"), isNull);
  });

  test("the DEV session is always signed in with a fixed token", () async {
    const source = DevNoLoginSessionDataSource();
    expect(source.currentSession()?["email"], DevNoLoginSessionDataSource.email);
    expect(await source.freshAccessToken(), DevNoLoginSessionDataSource.token);
    expect(
      await source.freshAccessToken(forceRefresh: true),
      DevNoLoginSessionDataSource.token,
    );
    expect(
      (await source.watchSession().first)?["email"],
      DevNoLoginSessionDataSource.email,
    );
    expect(source.redirectError(), isEmpty);
  });
}
