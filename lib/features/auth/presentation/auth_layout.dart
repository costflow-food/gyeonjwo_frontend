import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_font_sizes.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/workspace_colors.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.backPath,
    this.maxWidth = 1080,
    this.compact = false,
  });

  final Widget child;
  final String? backPath;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth + 64),
                    padding: EdgeInsets.all(compact ? 20 : 32),
                    decoration: BoxDecoration(
                      color: context.palette.frame,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            const SizedBox(width: 132, child: BrandLogo()),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 32),
                        if (backPath != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => context.go(backPath!),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('이전으로'),
                              style: TextButton.styleFrom(
                                foregroundColor: context.palette.muted,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 16 : 32,
                          ),
                          child: child,
                        ),
                        SizedBox(height: compact ? 4 : 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '견줘 · 근거를 모아, 더 선명한 구매 검토.',
                            style: TextStyle(
                              fontSize: AppFontSizes.secondary,
                              color: context.palette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding:
        padding ??
        EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 22 : 36),
    decoration: BoxDecoration(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: context.palette.ink.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.step,
    required this.title,
    required this.description,
  });
  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: context.palette.blush,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          step,
          style: TextStyle(
            color: context.palette.accentText,
            fontSize: AppFontSizes.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSizes.pageTitle,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        description,
        style: TextStyle(
          fontSize: AppFontSizes.bodyLarge,
          color: context.palette.muted,
          height: 1.8,
        ),
      ),
      const SizedBox(height: 28),
    ],
  );
}

class AuthInfoTile extends StatelessWidget {
  const AuthInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.enabled = true,
    this.status,
    this.statusColor,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final String? status;

  /// 기본은 켜져 있으면 초록, 꺼져 있으면 흐린 색입니다.
  final Color? statusColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled ? context.palette.surface : context.palette.canvas,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? context.palette.accentText : context.palette.muted,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSizes.bodyLarge,
                  fontWeight: FontWeight.w700,
                  color: enabled ? context.palette.ink : context.palette.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: context.palette.muted,
                  height: 1.7,
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: 6),
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w600,
                    color:
                        statusColor ??
                        (enabled
                            ? const Color(0xFF00754A)
                            : context.palette.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class AuthNotice extends StatelessWidget {
  const AuthNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.palette.panel,
      border: Border.all(color: context.palette.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: AppFontSizes.body,
        color: context.palette.muted,
        height: 1.8,
      ),
    ),
  );
}

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: context.palette.accent,
        foregroundColor: context.palette.onAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: const StadiumBorder(),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.buttonLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(icon, size: 18),
        ],
      ),
    ),
  );
}
