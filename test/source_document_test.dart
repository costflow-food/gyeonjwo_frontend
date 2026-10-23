import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeonjwo_frontend/features/source_document/presentation/source_document_dialog.dart';
import 'package:gyeonjwo_frontend/app/app_router.dart';
import 'package:gyeonjwo_frontend/main.dart';

void main() {
  for (final size in [const Size(1440, 1000), const Size(320, 480)]) {
    testWidgets('Source document fits $size with large text and closes', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showSourceDocument(
                    context,
                    requestId: 'REQ-2026-1019-003',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('원문·근거 보기'), findsOneWidget);
      expect(find.text('A사 영업담당 (합성)'), findsOneWidget);
      expect(find.text('[단가변경] 11월 냉동 딸기 공급단가 조정 안내'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('이전 화면으로'), findsNothing);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(SourceDocumentDialog), findsNothing);
    });
  }

  testWidgets(
    'Queue and review open the selected document; unavailable document is not substituted',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      appRouter.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.text('[단가변경] 11월 냉동 딸기 공급단가 조정 안내'));
      await tester.pumpAndSettle();
      expect(find.byType(SourceDocumentDialog), findsOneWidget);
      expect(find.text('A사 영업담당 (합성)'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('[단가변경] 냉동 딸기 견적 단가 확인 요청'));
      await tester.pumpAndSettle();
      expect(find.text('이 요청의 합성 원문이 준비되지 않았습니다.'), findsOneWidget);
      expect(find.text('A사 영업담당 (합성)'), findsNothing);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      appRouter.go('/review');
      await tester.pumpAndSettle();
      await tester.tap(find.text('요청 원문 보기'));
      await tester.pumpAndSettle();
      expect(find.text('A사 영업담당 (합성)'), findsOneWidget);
      expect(find.text('이전 화면으로'), findsNothing);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('단가변경 검토'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
