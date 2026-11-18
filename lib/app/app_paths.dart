/// 앱 화면 주소 (KAN-321). 화면 사이 이동은 이 상수와 함수만 씁니다.
abstract final class AppPaths {
  /// 로그인 후 첫 화면.
  static const dashboard = "/";
  static const tasks = "/tasks";
  static const transactions = "/transactions";
  static const suppliers = "/suppliers";
  static const logs = "/logs";
  static const account = "/account";

  static String task(String caseId) => "$tasks/$caseId";
  static String review(String caseId) => "$tasks/$caseId/review";

  /// Suppliers 품목 카드 '마지막 실거래'에서 여는 Transactions(7.12):
  /// 그 거래처 품목(`supplier_item`)·품목 이름(`item`)·거래일(`date`)로
  /// 걸러 그 거래를 고릅니다.
  static String transactionsFor({
    required String supplierItemId,
    String? itemName,
    String? date,
  }) => Uri(
    path: transactions,
    queryParameters: {
      "supplier_item": supplierItemId,
      "item": ?itemName,
      "date": ?date,
    },
  ).toString();

  /// Tasks 주소에 상태 탭(`?tab=`)을 붙입니다. [tab]이 null이면 전체 탭입니다.
  static String tasksAt({String? caseId, String? tab}) => Uri(
    path: caseId == null ? tasks : task(caseId),
    queryParameters: tab == null ? null : {"tab": tab},
  ).toString();
}

/// 옛 업무 주소(`/cases/:id`, `/cases/:id/review`)를 새 주소로 바꿉니다.
/// 메일·로그에 남은 옛 링크가 계속 열리게 합니다. 해당 없으면 null.
String? legacyCaseRedirect(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length < 2 || segments.first != "cases") return null;
  final rest = segments.skip(1).join("/");
  return Uri(
    path: "${AppPaths.tasks}/$rest",
    query: uri.hasQuery ? uri.query : null,
  ).toString();
}
