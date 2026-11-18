import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/supplier/data/supplier_repository_impl.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier_repository.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/supplier_register_dialog.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_detail_content.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

const _supplier = SupplierDetail(
  id: "s1",
  name: "서산참농산",
  sourceType: SupplierSourceType.registered,
  businessRegistrationNo: "123-45-67890",
  contact: SupplierContact(name: "김담당", phone: "010-0000-0000"),
  contactEmail: "sales@example.invalid",
  location: "충남 서산",
  items: [
    SupplierItem(id: "i1", itemName: "깐마늘", certifications: [], unit: "kg"),
  ],
);

class _FakeRepository implements SupplierRepository {
  _FakeRepository({this.failure});

  final SupplierFailure? failure;
  final updates = <(String, Map<String, Object?>)>[];

  @override
  Future<SupplierPage> getSuppliers({
    String query = "",
    String? cursor,
  }) async => const SupplierPage(items: [], total: 0);

  @override
  Future<SupplierDetail> getSupplier(String supplierId) async => _supplier;

  @override
  Future<PriceHistory> getPriceHistory(String supplierItemId) async =>
      const PriceHistory(referenceQuotes: [], actualPurchases: []);

  @override
  Future<SupplierDetail> registerSupplier(SupplierDraft draft) =>
      throw UnimplementedError();

  @override
  Future<SupplierDetail> updateSupplier(
    String supplierId,
    Map<String, Object?> body,
  ) async {
    updates.add((supplierId, body));
    if (failure case final failure?) throw failure;
    return _supplier;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  SupplierRepository? repository,
}) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          supplierRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

Future<void> _openEdit(WidgetTester tester) async {
  await tester.tap(find.byTooltip("거래처 수정"));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the edit icon opens the form filled with the supplier", (
    tester,
  ) async {
    await _pump(tester, const SupplierDetailContent(supplier: _supplier));
    await _openEdit(tester);

    expect(find.text("거래처 수정"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "서산참농산"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "깐마늘"), findsOneWidget);
    expect(find.text("저장"), findsOneWidget);
  });

  testWidgets("saving sends only the changed fields and closes", (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(
      tester,
      const SupplierDetailContent(supplier: _supplier),
      repository: repository,
    );
    await _openEdit(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, "충남 서산"),
      "충남 당진",
    );
    await tester.tap(find.text("저장"));
    await tester.pumpAndSettle();

    expect(repository.updates, hasLength(1));
    final (supplierId, body) = repository.updates.single;
    expect(supplierId, "s1");
    expect(body, {"location": "충남 당진"});
    expect(find.byType(SupplierRegisterDialog), findsNothing);
  });

  testWidgets("saving without changes sends nothing and closes", (
    tester,
  ) async {
    final repository = _FakeRepository();
    await _pump(
      tester,
      const SupplierDetailContent(supplier: _supplier),
      repository: repository,
    );
    await _openEdit(tester);

    await tester.tap(find.text("저장"));
    await tester.pumpAndSettle();

    expect(repository.updates, isEmpty);
    expect(find.byType(SupplierRegisterDialog), findsNothing);
  });

  testWidgets("a server rejection is shown and the form stays open", (
    tester,
  ) async {
    final repository = _FakeRepository(
      failure: const SupplierFailure(
        "SUPPLIER_EMAIL_LOCKED",
        "진행 중인 업무가 있어 이메일을 바꿀 수 없습니다. 업무가 끝난 뒤 다시 시도해 주세요.",
      ),
    );
    await _pump(
      tester,
      const SupplierDetailContent(supplier: _supplier),
      repository: repository,
    );
    await _openEdit(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, "sales@example.invalid"),
      "new@example.invalid",
    );
    await tester.tap(find.text("저장"));
    await tester.pumpAndSettle();

    expect(
      find.text("진행 중인 업무가 있어 이메일을 바꿀 수 없습니다. 업무가 끝난 뒤 다시 시도해 주세요."),
      findsOneWidget,
    );
    expect(find.byType(SupplierRegisterDialog), findsOneWidget);
  });

  testWidgets("saved items cannot be deleted; added ones can", (tester) async {
    await _pump(tester, const SupplierDetailContent(supplier: _supplier));
    await _openEdit(tester);

    expect(find.byTooltip("품목 1 삭제"), findsNothing);
    await tester.tap(find.text("품목 추가"));
    await tester.pumpAndSettle();
    expect(find.byTooltip("품목 2 삭제"), findsOneWidget);
  });

  testWidgets("registration number is shown read-only", (tester) async {
    await _pump(tester, const SupplierDetailContent(supplier: _supplier));
    await _openEdit(tester);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, "123-45-67890"),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
    expect(field.enabled, isFalse);
  });

  testWidgets("web-verified suppliers have no edit button", (tester) async {
    const web = SupplierDetail(
      id: "s2",
      name: "웹 확인 업체",
      sourceType: SupplierSourceType.verifiedWeb,
      contact: SupplierContact(),
      items: [],
    );
    await _pump(tester, const SupplierDetailContent(supplier: web));

    expect(find.byTooltip("거래처 수정"), findsNothing);
  });

  testWidgets("the register form opens empty", (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showSupplierRegisterDialog(context),
          child: const Text("open"),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.text("거래처 등록"), findsOneWidget);
    expect(find.text("등록"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "서산참농산"), findsNothing);
  });
}
