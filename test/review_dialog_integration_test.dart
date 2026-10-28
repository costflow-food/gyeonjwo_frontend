import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeonjwo_frontend/app/app_router.dart';
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/features/purchase_review/data/purchase_review_data_source.dart";

import "support/controlled_review_data_source.dart";

void main() {
  testWidgets(
    'Progress continues while reading its source and the result keeps the same request',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      appRouter.go('/');
      final source = ControlledReviewDataSource();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            purchaseReviewDataSourceProvider.overrideWithValue(source),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '실행').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('디자인 시연 · A사 요청'), findsOneWidget);
      await tester.tap(find.byTooltip('검토 진행 닫기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, '진행 보기'), findsOneWidget);

      await tester.tap(find.text('[단가변경] 11월 냉동 딸기 공급단가 조정 안내'));
      await tester.pumpAndSettle();
      expect(find.text('원문·근거 보기'), findsOneWidget);
      expect(find.text('A사 영업담당 (합성)'), findsOneWidget);
      source.succeed("REQ-2026-1019-003");
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, '진행 보기'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '결과 보기'), findsNWidgets(3));

      await tester.tap(find.widgetWithText(OutlinedButton, '결과 보기').first);
      await tester.pumpAndSettle();
      expect(find.text('REQ-2026-1019-003 · 합성 시연 사례'), findsOneWidget);
      await tester.tap(find.text('요청 원문 보기'));
      await tester.pumpAndSettle();
      expect(find.text('A사 영업담당 (합성)'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('REQ-2026-1019-003 · 합성 시연 사례'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
