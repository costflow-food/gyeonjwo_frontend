import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/shared/lds_colors.dart";
import "package:gyeonjwo_frontend/shared/widgets/lds/lds.dart";

void main() {
  testWidgets("round tabs: 32 tall chips, dark selected, tap selects", (
    tester,
  ) async {
    var selected = "formal";
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LdsRoundTabs<String>(
              tabs: const [
                LdsTabItem(value: "formal", label: "격식체"),
                LdsTabItem(value: "polite", label: "부드러운 존댓말"),
              ],
              selected: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    Material chip(String label) => tester.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    expect(tester.getSize(find.byType(InkWell).first).height, 32);
    expect(chip("격식체").color, LdsColors.title);
    expect(chip("부드러운 존댓말").color, Colors.white);
    // A chip is as wide as its label, not the row.
    expect(tester.getSize(find.byType(InkWell).first).width, lessThan(200));
    await tester.tap(find.text("부드러운 존댓말"));
    await tester.pump();
    expect(selected, "polite");
    expect(chip("부드러운 존댓말").color, LdsColors.title);
    expect(
      tester.getSemantics(find.bySemanticsLabel("부드러운 존댓말")),
      matchesSemantics(
        label: "부드러운 존댓말",
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });
}
