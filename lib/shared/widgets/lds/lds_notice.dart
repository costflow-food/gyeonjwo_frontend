import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import 'lds_metrics.dart';

enum LdsNoticeTone {
  info(LdsColors.infoBg, LdsColors.info, LdsColors.infoText),
  success(LdsColors.successBg, LdsColors.success, LdsColors.successText),
  warning(LdsColors.warningBg, LdsColors.warning, LdsColors.warningText),
  error(LdsColors.errorBg, LdsColors.error, LdsColors.errorText);

  const LdsNoticeTone(this.background, this.accent, this.text);

  final Color background;

  /// 점·아이콘 색.
  final Color accent;

  /// 연한 바탕 위 제목 글자(4.5:1 이상).
  final Color text;
}

/// 안내 띠: 상태 알림(서버·메일함·권한)과 모달 안 안내 한 줄.
///
/// 톤 바탕 + 왼쪽 아이콘(없으면 점 8) + **제목**(톤 글자, 700) + 설명(14px
/// `#333D4B`) + 오른쪽 동작 버튼. [banner]는 화면 폭 전체 띠(모서리 없음),
/// 아니면 모서리 8 상자입니다. 제목과 설명은 한 문장처럼 이어 붙여 줄바꿈합니다.
class LdsNotice extends StatelessWidget {
  const LdsNotice({
    super.key,
    this.tone = LdsNoticeTone.info,
    this.title,
    this.message,
    this.icon,
    this.action,
    this.banner = false,
  }) : assert(title != null || message != null);

  final LdsNoticeTone tone;
  final String? title;
  final String? message;
  final IconData? icon;

  /// 오른쪽 동작(예: `LdsButton` small). 좁으면 글 아래로 내려갑니다.
  final Widget? action;
  final bool banner;

  @override
  Widget build(BuildContext context) {
    final leading = icon == null
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tone.accent,
              shape: BoxShape.circle,
            ),
          )
        : Icon(icon, size: 18, color: tone.text);
    final text = Text.rich(
      TextSpan(
        children: [
          if (title != null)
            TextSpan(
              text: title,
              style: TextStyle(fontWeight: FontWeight.w700, color: tone.text),
            ),
          if (title != null && message != null) const TextSpan(text: '  '),
          if (message != null) TextSpan(text: message),
        ],
      ),
      style: const TextStyle(fontSize: 14, height: 1.5, color: LdsColors.title),
    );
    return Container(
      padding: banner
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: banner ? null : BorderRadius.circular(LdsRadius.table),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                // 첫 줄 가운데(14px × 1.5)에 맞춥니다.
                height: MediaQuery.textScalerOf(context).scale(14) * 1.5,
                child: Center(child: leading),
              ),
              const SizedBox(width: 8),
              Expanded(child: text),
            ],
          );
          final button = action;
          if (button == null) return body;
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                body,
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: button,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: body),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}
