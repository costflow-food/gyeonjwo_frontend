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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: 132, child: BrandLogo()),
                            Chip(
                              avatar: Icon(
                                Icons.design_services_outlined,
                                size: 16,
                              ),
                              label: Text('UI 미리보기 · 실제 계정 연결 전'),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: line),
                            ),
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
                                foregroundColor: muted,
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 16 : 32,
                          ),
                          child: child,
                        ),
                        SizedBox(height: compact ? 8 : 32),
                        const Divider(color: line),
                        Padding(
                          padding: EdgeInsets.only(top: compact ? 8 : 16),
                          child: const Text(
                            '견줘 · 근거를 모아, 더 선명한 구매 검토.',
                            style: TextStyle(
                              fontSize: AppFontSizes.secondary,
                              color: muted,
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
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(16),
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
      Text(
        step,
        style: const TextStyle(
          color: accent,
          fontSize: AppFontSizes.secondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSizes.pageTitle,
          fontWeight: FontWeight.w800,
          height: 1.35,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        description,
        style: const TextStyle(
          fontSize: AppFontSizes.bodyLarge,
          color: muted,
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
  });
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final String? status;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled ? blush : canvas,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: enabled ? accent : muted),
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
                  color: enabled ? ink : muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: AppFontSizes.body,
                  color: muted,
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
                    color: enabled ? const Color(0xFF287451) : muted,
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
      color: canvas,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: AppFontSizes.body,
        color: muted,
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
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
