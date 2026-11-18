import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:gyeonjwo_frontend/features/supplier/domain/supplier_list_state.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_header.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_list_status.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

Future<void> _pump(WidgetTester tester, Widget child) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("header buttons look like the Invoices buttons (neutral)", (
    tester,
  ) async {
    await _pump(tester, SupplierHeader(onRefresh: () {}, onRegister: () {}));
    for (final label in ["새로고침", "거래처 등록"]) {
      final button = tester.widget<LdsButton>(
        find.widgetWithText(LdsButton, label),
      );
      expect(button.variant, LdsButtonVariant.outlinedNeutral, reason: label);
    }
  });

  testWidgets("sort is the same button as Invoices '최신순 ▾'", (tester) async {
    SupplierSort? chosen;
    await _pump(
      tester,
      SupplierSortSelect(
        value: SupplierSort.name,
        onChanged: (sort) => chosen = sort,
      ),
    );
    expect(find.byType(LdsSortButton<SupplierSort>), findsOneWidget);
    expect(find.byType(DropdownButton<SupplierSort>), findsNothing);
    final button = find.bySemanticsLabel("정렬, 이름순");
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, 36);

    await tester.tap(button);
    await tester.pumpAndSettle();
    for (final sort in SupplierSort.values) {
      expect(find.bySemanticsLabel("${sort.label} 정렬"), findsOneWidget);
    }
    // Not available yet: shown but can't be chosen.
    await tester.tap(find.bySemanticsLabel("최근 거래순 정렬"));
    await tester.pumpAndSettle();
    expect(chosen, isNull);

    await tester.tap(find.bySemanticsLabel("품목 많은 순 정렬"));
    await tester.pumpAndSettle();
    expect(chosen, SupplierSort.itemCount);
  });

  testWidgets("narrow, load failed, '품목 많은 순': the row still fits", (
    tester,
  ) async {
    for (final scale in [1.0, 1.3]) {
      await _pump(
        tester,
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SizedBox(
            width: 328,
            child: SupplierListStatus(
              data: const SupplierListState(
                query: "",
                suppliers: [],
                total: 2,
                sort: SupplierSort.itemCount,
                loadFailed: true,
              ),
              onRetry: () {},
              onSort: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: "scale $scale");
      expect(find.bySemanticsLabel("정렬, 품목 많은 순"), findsOneWidget);
    }
  });
}
