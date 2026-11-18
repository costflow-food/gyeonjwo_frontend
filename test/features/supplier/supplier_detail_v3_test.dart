import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:gyeonjwo_frontend/features/supplier/domain/supplier.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_detail_content.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_item_card.dart";
import "package:gyeonjwo_frontend/features/supplier/presentation/widgets/supplier_list_row.dart";
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../../helpers/platform_override.dart";

SupplierItem _item(String id, String name, {String? price}) => SupplierItem(
  id: id,
  itemName: name,
  specification: "IQF 홀 / 10kg 박스",
  unit: "kg",
  unitsPerBox: "10",
  weightPerBox: "10",
  origin: "국산",
  certifications: const [
    Certification(name: "HACCP", status: CertificationStatus.confirmed),
  ],
  notes: "11월부터 공급단가 조정 예정",
  latestReferenceQuote: price == null
      ? null
      : ReferenceQuote(
          unitPrice: price,
          unit: "kg",
          effectiveFrom: "2026-11-01",
        ),
  lastPurchase: const LastPurchase(
    unitPrice: "5000",
    unit: "kg",
    transactionDate: "2026-10-10",
  ),
);

SupplierDetail _supplier({SourceEvidence? evidence}) => SupplierDetail(
  id: "s1",
  name: "한라푸드",
  sourceType: SupplierSourceType.registered,
  contact: const SupplierContact(name: "김영업", phone: "02-0000-0001"),
  businessRegistrationNo: "214-81-00001",
  contactEmail: "sales@a-supplier.example.com",
  location: "경기 이천시",
  evidence: evidence,
  items: [
    _item("i1", "냉동 딸기", price: "5500"),
    _item("i2", "냉동 블루베리", price: "7200"),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 760,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  tester.view.physicalSize = const Size(1440, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(WorkspacePalette.lds),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("only the first item starts open; a folded one shows its quote", (
    tester,
  ) async {
    await _pump(tester, SupplierDetailContent(supplier: _supplier()));
    final cards = find.byType(SupplierItemCard);
    expect(cards, findsNWidgets(2));
    // First open: the summary boxes and the spec block.
    expect(
      find.descendant(of: cards.first, matching: find.text("최근 참고 견적")),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cards.first, matching: find.text("박스당 수량")),
      findsOneWidget,
    );
    // Second folded: only its name, spec and latest quote.
    expect(
      find.descendant(of: cards.last, matching: find.text("박스당 수량")),
      findsNothing,
    );
    expect(
      find.descendant(
        of: cards.last,
        matching: find.text("최근 참고 견적 7,200원/kg"),
      ),
      findsOneWidget,
    );
    // The whole name row unfolds it.
    await tester.tap(find.text("냉동 블루베리"));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: cards.last, matching: find.text("박스당 수량")),
      findsOneWidget,
    );
    expect(find.text("최근 참고 견적 7,200원/kg"), findsNothing);
  });

  testWidgets("supplier info is a label-value table, two columns when wide", (
    tester,
  ) async {
    await _pump(tester, SupplierDetailContent(supplier: _supplier()));
    final tables = find.byType(LdsKeyValueTable);
    // Left, right and the full-width 기준자료 row.
    expect(tables, findsNWidgets(3));
    final left = tester.getRect(tables.at(0));
    final right = tester.getRect(tables.at(1));
    expect(right.top, left.top);
    expect(right.left, greaterThan(left.right));
    final source = tester.getRect(tables.at(2));
    expect(source.width, closeTo(760, 1));
    expect(
      tester.widget<LdsKeyValueTable>(tables.first).labelWidth,
      greaterThanOrEqualTo(96),
    );
  });

  testWidgets("narrow: one table, then the 기준자료 row", (tester) async {
    await _pump(
      tester,
      SupplierDetailContent(supplier: _supplier()),
      width: 420,
    );
    expect(find.byType(LdsKeyValueTable), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets("no 기준자료: '등록된 기준자료 없음'", (tester) async {
    await _pump(tester, SupplierDetailContent(supplier: _supplier()));
    expect(find.text("등록된 기준자료 없음"), findsOneWidget);
  });

  testWidgets("a 기준자료 shows the document name only", (tester) async {
    await _pump(
      tester,
      SupplierDetailContent(
        supplier: _supplier(
          evidence: const SourceEvidence(
            label: "기존 거래 계약서",
            checkedAt: "2026-10-01T00:00:00Z",
            memo: "연 단가 계약",
            sourceMailId: "m1",
          ),
        ),
      ),
    );
    expect(find.text("기존 거래 계약서"), findsOneWidget);
    // Date and memo are not on the line; they are in the tooltip.
    expect(find.textContaining("연 단가 계약"), findsNothing);
    expect(find.byTooltip(RegExp("연 단가 계약")), findsOneWidget);
    expect(find.bySemanticsLabel("기준자료 기존 거래 계약서, 원문 보기"), findsOneWidget);
  });

  testWidgets("a selected supplier card has an orange 2px border", (
    tester,
  ) async {
    const summary = SupplierSummary(
      id: "s1",
      name: "한라푸드",
      sourceType: SupplierSourceType.registered,
      itemNames: ["냉동 딸기", "냉동 블루베리", "깐마늘", "대파"],
      location: "경기 이천시",
    );
    await _pump(
      tester,
      SupplierListRow(supplier: summary, selected: true, onTap: () {}),
      width: 400,
    );
    final shape =
        tester
                .widget<Material>(
                  find
                      .descendant(
                        of: find.byType(SupplierListRow),
                        matching: find.byType(Material),
                      )
                      .first,
                )
                .shape!
            as RoundedRectangleBorder;
    expect(shape.side.color, LdsColors.primary);
    expect(shape.side.width, 2);
    // Three chips and the rest counted; a chip is as wide as its name.
    expect(find.text("+1"), findsOneWidget);
    expect(
      tester.getSize(find.text("깐마늘")).width + 20 + 2,
      closeTo(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text("깐마늘"),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .width,
        1,
      ),
    );
  });
}
