import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/lds_colors.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/lds/lds.dart';
import '../../../shared/widgets/mobile_scaffold.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.backPath,
    this.phoneBackPath,
    this.maxWidth = 1080,
    this.compact = false,
  });

  final Widget child;
  final String? backPath;

  /// Where back leads on a phone instead of [backPath], when set.
  final String? phoneBackPath;
  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final phone = isCompactLayout(context);
    final backPath = phone ? phoneBackPath ?? this.backPath : this.backPath;
    final scaffold = _scaffold(context, backPath);
    if (!phone || backPath == null) return scaffold;
    // These screens are opened with go, so there is nothing under them to
    // pop to: system back would leave the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(backPath);
      },
      child: scaffold,
    );
  }

  Widget _scaffold(BuildContext context, String? backPath) {
    return Scaffold(
      backgroundColor: LdsColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Phones: give the content the width instead of the margins.
            final narrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 16 : 24,
                    vertical: narrow ? 20 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(width: 132, child: BrandLogo()),
                          ),
                          // 시안: 로그인은 로고 아래 32 + 본문 위 여백 32,
                          // 안내·연결은 로고 아래 12에 '이전으로', 그 아래 16.
                          SizedBox(height: compact ? 12 : 64),
                          if (backPath != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => context.go(backPath),
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('이전으로'),
                                style: TextButton.styleFrom(
                                  foregroundColor: LdsColors.muted,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          child,
                          const SizedBox(height: 32),
                          const Divider(height: 1, color: LdsColors.line),
                          const SizedBox(height: 16),
                          const Text(
                            'Thoner · 근거를 모아, 더 선명한 구매 검토.',
                            style: TextStyle(
                              fontSize: 13,
                              color: LdsColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 흰 카드: 1px `#E5E7EA`, 모서리 16, 그림자 없음.
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
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

/// 연결됨 표시 글자·아이콘(시안 `--success-deep`).
const authSuccessDeep = Color(0xFF2D660A);

/// 단계 표시(주황 글자 13/700, 자간 1) · 제목 28/800 · 설명.
class AuthStep extends StatelessWidget {
  const AuthStep(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: LdsColors.primary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
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
      AuthStep(step),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.35,
          letterSpacing: -1,
          color: LdsColors.ink,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        description,
        style: const TextStyle(
          fontSize: 15,
          color: LdsColors.muted,
          height: 1.8,
        ),
      ),
      const SizedBox(height: 28),
    ],
  );
}

/// 아이콘 칸 40(모서리 10, 연한 주황) + 제목 15/700 + 설명 14.
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

  final Color? statusColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthIconBox(icon: icon, enabled: enabled, radius: 10),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: enabled ? LdsColors.ink : LdsColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: LdsColors.muted,
                  height: 1.7,
                ),
              ),
              if (status != null) ...[
                const SizedBox(height: 6),
                Text(
                  status!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        statusColor ??
                        (enabled
                            ? LdsColors.successText
                            : LdsColors.muted),
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

/// 아이콘 칸: 40×40, 모서리 8(기본). 켜짐 = 연한 주황 바탕 + 주황 아이콘.
class AuthIconBox extends StatelessWidget {
  const AuthIconBox({
    super.key,
    required this.icon,
    this.enabled = true,
    this.size = 40,
    this.iconSize,
    this.radius = 8,
    this.color,
    this.background,
  });

  final IconData icon;
  final bool enabled;
  final double size;

  /// 기본은 칸의 절반.
  final double? iconSize;
  final double radius;
  final Color? color, background;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background ?? (enabled ? LdsColors.primarySoft : LdsColors.canvas),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(
      icon,
      size: iconSize ?? size / 2,
      color: color ?? (enabled ? LdsColors.primary : LdsColors.muted),
    ),
  );
}

/// 안내 상자: 연회색 바탕, 1px 선, 모서리 10.
class AuthNotice extends StatelessWidget {
  const AuthNotice({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: LdsColors.canvas,
      border: Border.all(color: LdsColors.line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: LdsColors.muted,
        height: 1.8,
      ),
    ),
  );
}

/// 큰 버튼(7.4 large: 높이 48), 폭 전체, 글자 뒤 화살표.
/// 시안의 인증 화면 버튼은 모서리 8이라 LDS 버튼(6)을 8로 깎아 씁니다.
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LdsButton(
        label: label,
        size: LdsButtonSize.large,
        trailingIcon: icon,
        onPressed: onPressed,
      ),
    ),
  );
}
