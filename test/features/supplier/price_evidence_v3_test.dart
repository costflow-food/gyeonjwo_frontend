import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/price_history_section.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

const _history = PriceHistory(
  referenceQuotes: [
    PriceRecord(
      unitPrice: "5500",
      unit: "kg",
      sourceLabel: "단가변경 안내 메일",
      date: "2026-11-01",
      conditions: "월 1,000kg 기준",
      sourceMailId: "m1",
    ),
    PriceRecord(
      unitPrice: "5000",
      unit: "kg",
      sourceLabel: "상반기 견적 메일",
      date: "2026-05-01",
    ),
  ],
  actualPurchases: [
    PriceRecord(
      unitPrice: "5000",
      unit: "kg",
      sourceLabel: "거래명세서",
      date: "2026-10-10",
      quantity: "800",
    ),
    PriceRecord(
      unitPrice: "5000",
      unit: "kg",
      sourceLabel: "영수증",
      date: "2026-09-08",
      quantity: "1000",
    ),
  ],
);

Future<void> _pump(WidgetTester tester, {double width = 820}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(WorkspacePalette.lds),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const PriceHistoryView(history: _history),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _in(String key, Finder finder) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: finder);

void main() {
  testWidgets("quotes and purchases stack with the same column widths", (
    tester,
  ) async {
    await _pump(tester);
    final tables = find.byType(LdsListTable);
    expect(tables, findsNWidgets(2));
    // Stacked, not side by side.
    expect(
      tester.getTopLeft(tables.last).dy,
      greaterThan(tester.getBottomLeft(tables.first).dy),
    );
    const quoteHeads = ["적용일", "단가", "조건", "출처"];
    const purchaseHeads = ["거래일", "단가", "수량", "증빙"];
    for (var i = 0; i < 4; i++) {
      final quote = tester.getRect(
        _in("quote-table", find.text(quoteHeads[i])).first,
      );
      final purchase = tester.getRect(
        _in("purchase-table", find.text(purchaseHeads[i])).first,
      );
      expect(purchase.left, closeTo(quote.left, .5));
      expect(purchase.width, closeTo(quote.width, .5));
    }
  });

  testWidgets("the newest row of each table is marked '최신'", (tester) async {
    await _pump(tester);
    for (final key in ["quote-table", "purchase-table"]) {
      final table = tester.widget<LdsListTable>(
        _in(key, find.byType(LdsListTable)),
      );
      expect(table.rows.first.latest, isTrue);
      expect(table.rows.skip(1).any((row) => row.latest), isFalse);
      expect(_in(key, find.byType(LdsLatestTag)), findsOneWidget);
    }
    // The tag sits in the first (newest) row, above the older one.
    final tag = tester.getCenter(find.byType(LdsLatestTag).first).dy;
    expect(tag, greaterThan(tester.getTopLeft(find.text("2026.11.01")).dy));
    expect(tag, lessThan(tester.getTopLeft(find.text("2026.05.01")).dy));
  });

  testWidgets("summary: latest quote, latest purchase and the gap", (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text("최근 참고 견적"), findsOneWidget);
    expect(find.text("최근 실제 거래"), findsOneWidget);
    expect(find.textContaining("+500"), findsOneWidget);
    expect(find.text("견적이 10% 높음"), findsOneWidget);
    // Summary cells are not a table.
    expect(find.byType(LdsKeyValueTable), findsNothing);
    // Empty cells stay blank; the source opens the mail.
    expect(find.text("원문 보기"), findsOneWidget);
  });

  test("the gap is only computed for two prices in the same unit", () {
    const quote = PriceRecord(unitPrice: "4500", unit: "kg", sourceLabel: "");
    const paid = PriceRecord(unitPrice: "5000", unit: "kg", sourceLabel: "");
    expect(priceGapOf(quote, paid)?.number, "-500");
    expect(priceGapOf(quote, paid)?.caption, "견적이 10% 낮음");
    expect(
      priceGapOf(
        quote,
        const PriceRecord(unitPrice: "5000", unit: "box", sourceLabel: ""),
      ),
      isNull,
    );
    expect(priceGapOf(null, paid), isNull);
  });

  testWidgets("narrow: each record is a label-value table, no overflow", (
    tester,
  ) async {
    await _pump(tester, width: 340);
    expect(find.byType(LdsListTable), findsNothing);
    expect(find.byType(LdsKeyValueTable), findsNWidgets(4));
    expect(find.byType(LdsLatestTag), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets("latest rows use the light orange background", (tester) async {
    await _pump(tester);
    final rows = tester.widgetList<Container>(
      _in("quote-table", find.byType(Container)),
    );
    expect(
      rows.where(
        (row) =>
            (row.decoration as BoxDecoration?)?.color == LdsColors.primaryRow,
      ),
      hasLength(1),
    );
  });
}
