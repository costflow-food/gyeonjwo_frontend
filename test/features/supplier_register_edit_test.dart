import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/supplier_register_dialog.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_detail_content.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

const _supplier = SupplierDetail(
  id: "s1",
  name: "서산참농산",
  sourceType: SupplierSourceType.registered,
  contact: SupplierContact(name: "김담당", phone: "010-0000-0000"),
  contactEmail: "sales@example.invalid",
  location: "충남 서산",
  items: [
    SupplierItem(id: "i1", itemName: "깐마늘", certifications: [], unit: "kg"),
  ],
);

Future<void> _pump(WidgetTester tester, Widget child) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [WorkspacePalette.houseGreen]),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets("the edit icon opens the form filled with the supplier", (
    tester,
  ) async {
    await _pump(tester, const SupplierDetailContent(supplier: _supplier));

    await tester.tap(find.byTooltip("거래처 수정"));
    await tester.pumpAndSettle();

    expect(find.text("거래처 수정"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "서산참농산"), findsOneWidget);
    expect(find.widgetWithText(TextFormField, "깐마늘"), findsOneWidget);
    expect(find.text("저장"), findsOneWidget);
  });

  testWidgets("saving an edit says it failed while the server has no update", (
    tester,
  ) async {
    await _pump(tester, const SupplierDetailContent(supplier: _supplier));
    await tester.tap(find.byTooltip("거래처 수정"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("저장"));
    await tester.pumpAndSettle();

    expect(find.text("거래처를 수정하지 못했습니다."), findsOneWidget);
    // Still open, so nothing typed is lost.
    expect(find.byType(SupplierRegisterDialog), findsOneWidget);
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
