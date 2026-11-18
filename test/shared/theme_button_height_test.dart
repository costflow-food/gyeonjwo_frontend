import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide testWidgets;
import "package:gyeonjwo_frontend/main.dart";
import "package:gyeonjwo_frontend/shared/widgets/workspace_button_styles.dart";
import "package:gyeonjwo_frontend/shared/workspace_colors.dart";

import "../helpers/platform_override.dart";

/// SSOT 7.4: a medium button is 36 tall. Desktop platforms default to the
/// compact visual density, which would draw it 28 tall on the web.
void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
    testWidgets("theme buttons are 36 tall on $platform", (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(WorkspacePalette.lds),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  FilledButton(onPressed: () {}, child: const Text("확인")),
                  OutlinedButton(onPressed: () {}, child: const Text("취소")),
                  TextButton(onPressed: () {}, child: const Text("닫기")),
                  FilledButton(
                    style: WorkspaceButtonStyles.filled(context),
                    onPressed: () {},
                    child: const Text("저장"),
                  ),
                  OutlinedButton(
                    style: WorkspaceButtonStyles.outlined(context),
                    onPressed: () {},
                    child: const Text("보류"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in ["확인", "취소", "닫기", "저장", "보류"]) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        );
        expect(tester.getSize(button).height, 36, reason: label);
      }
    });
  }
}
