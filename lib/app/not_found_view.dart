import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../shared/app_font_sizes.dart";
import "../shared/widgets/brand_logo.dart";
import "../shared/widgets/workspace_button_styles.dart";
import "../shared/workspace_colors.dart";

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.frame,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BrandLogo fills the width it is given; keep it logo-sized so
                // it sits centered with the text below.
                const SizedBox(width: 110, child: BrandLogo()),
                const SizedBox(height: 28),
                Text(
                  "페이지를 찾을 수 없습니다",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSizes.heading,
                    fontWeight: FontWeight.w700,
                    color: context.palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "주소가 바뀌었거나 잘못 입력됐을 수 있습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSizes.bodyLarge,
                    color: context.palette.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: WorkspaceButtonStyles.filled(context),
                  onPressed: () => context.go("/"),
                  child: const Text("업무 큐로 이동"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
