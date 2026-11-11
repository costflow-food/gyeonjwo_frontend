import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../app_font_sizes.dart";
import "../widgets/mobile_scaffold.dart";
import "../widgets/workspace_button_styles.dart";
import "../workspace_colors.dart";
import "workspace_theme.dart";

class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(workspaceThemeProvider);
    final dark = ref.watch(workspaceDarkModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "화면 테마",
          style: TextStyle(
            fontSize: AppFontSizes.cardTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isCompactLayout(context)
              ? "고른 모드와 색은 이 기기에만 저장됩니다."
              : "고른 모드와 색은 이 브라우저에만 저장됩니다.",
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: context.palette.muted,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 120,
            child: SegmentedButton<bool>(
              style: WorkspaceButtonStyles.segmented(context),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  tooltip: "라이트 모드",
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  tooltip: "다크 모드",
                ),
              ],
              selected: {dark},
              onSelectionChanged: (value) =>
                  ref.read(workspaceDarkModeProvider.notifier).set(value.first),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two to a row on a phone instead of one lonely tile.
            final width = constraints.maxWidth < 2 * _ThemeTile.width + 12
                ? (constraints.maxWidth - 12) / 2
                : _ThemeTile.width;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final palette in WorkspacePalette.all)
                  SizedBox(
                    width: width,
                    child: _ThemeTile(
                      palette: dark ? palette.toDark() : palette,
                      selected: palette.id == current.id,
                      onTap: () => ref
                          .read(workspaceThemeProvider.notifier)
                          .select(palette),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  /// Default width; the picker narrows it on a phone.
  static const width = 156.0;

  final WorkspacePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      label: palette.name,
      child: Material(
        color: current.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? current.accentText : current.line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 64,
                  color: palette.frame,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [palette.deepLight, palette.deep],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Dot(palette.accent),
                          _Dot(palette.blush),
                          _Dot(palette.gold),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          palette.name,
                          style: TextStyle(
                            fontSize: AppFontSizes.secondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: current.accentText,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black.withValues(alpha: .08)),
    ),
  );
}
