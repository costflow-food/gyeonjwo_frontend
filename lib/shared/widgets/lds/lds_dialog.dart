import 'package:flutter/material.dart';

import '../../lds_colors.dart';
import '../mobile_scaffold.dart';
import 'lds_metrics.dart';

/// 모달 틀 (`docs/design-ssot.md` 8.1).
///
/// 흰 바탕 · 모서리 16 · 제목 21px/700 줄간격 1.3. 닫기 버튼은 오른쪽 위 16에
/// 32×32(모서리 4, 아이콘 20 `#333D4B`, hover `#F2F4F6`, 포커스 주황 2px),
/// 머리 오른쪽 여백 60은 닫기 버튼 자리입니다. 본문은 스크롤되고 [actions]는 아래에 고정됩니다.
/// 머리 아래·버튼 줄 위의 구분선과 [subtitle]은 시안(v3) 모달을 따릅니다.
/// 모달 안 보조 동작은 글자 버튼(`TextButton`, 테마의 neutral ghost)으로 둡니다.
/// 휴대폰에서는 전체 화면으로 엽니다. [inSheet]이면 틀 없이 내용만 그려
/// 아래에서 올라오는 시트(`showModalBottomSheet`) 안에 넣을 수 있습니다.
class LdsDialog extends StatelessWidget {
  const LdsDialog({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    required this.child,
    this.actions = const [],
    this.maxWidth = 560,
    this.onClose,
    this.footerNote,
    this.footer,
    this.headerAction,
    this.inSheet = false,
  });

  final String title;

  /// 제목 위 작은 줄(예: '거래처·견적 근거'). 13px `#6B7583`.
  final String? overline;

  /// 제목 아래 보조 줄(예: 업무 제목). 13px `#6B7583`.
  final String? subtitle;

  /// 스크롤되는 본문.
  final Widget child;

  /// 아래 버튼 줄. 오른쪽 정렬, 사이 8.
  final List<Widget> actions;
  final double maxWidth;

  /// 닫기 버튼. 없으면 `Navigator.pop`.
  final VoidCallback? onClose;

  /// 아래 줄 왼쪽 안내(예: '창을 닫아도 검토는 서버에서 계속됩니다.'). 13px `#6B7583`.
  final String? footerNote;

  /// 아래 줄을 통째로 바꿀 때(예: 오류 줄 + 버튼). 주면 [actions]·[footerNote]는
  /// 쓰지 않습니다.
  final Widget? footer;

  /// 닫기 버튼 왼쪽 작은 단추(예: 새로고침 `LdsIconButton`).
  final Widget? headerAction;

  /// 시트 안에 넣을 때: [Dialog] 틀 없이 내용만.
  final bool inSheet;

  static const _padding = 24.0;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          // 머리 구분선이 모달 폭 전체에 그어지도록 폭을 넘겨줍니다.
          fit: StackFit.passthrough,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                _padding,
                _padding,
                headerAction == null ? 60 : 104,
                16,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: LdsColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overline != null) ...[
                    Text(
                      overline!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: LdsColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (headerAction != null)
              Positioned(top: 16, right: 56, child: headerAction!),
            Positioned(
              top: 16,
              right: 16,
              child: LdsDialogCloseButton(
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
        Flexible(
          fit: isCompactLayout(context) && !inSheet
              ? FlexFit.tight
              : FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_padding),
            child: child,
          ),
        ),
        if (actions.isNotEmpty || footerNote != null || footer != null)
          Container(
            padding: const EdgeInsets.fromLTRB(_padding, 16, _padding, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: LdsColors.line)),
            ),
            child: footer ?? _footer(),
          ),
      ],
    );
    if (inSheet) return body;
    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: SafeArea(child: body),
      );
    }
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LdsRadius.dialog),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );
  }
}

extension on LdsDialog {
  Widget _footer() {
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
    final note = footerNote;
    if (note == null) return buttons;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Text(
          note,
          style: const TextStyle(fontSize: 13, color: LdsColors.muted),
        ),
        buttons,
      ],
    );
  }
}

/// 모달 닫기 버튼: 32×32, 모서리 4, 아이콘 20 `#333D4B`, hover `#F2F4F6`, 포커스 주황 2px.
class LdsDialogCloseButton extends StatelessWidget {
  const LdsDialogCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: '닫기',
    icon: const Icon(Icons.close, size: 20),
    style: ButtonStyle(
      visualDensity: VisualDensity.standard,
      fixedSize: const WidgetStatePropertyAll(Size.square(32)),
      minimumSize: const WidgetStatePropertyAll(Size.square(32)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: const WidgetStatePropertyAll(LdsColors.title),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? LdsColors.badgeNeutralBg
            : Colors.transparent,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStateProperty.resolveWith(
        (states) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LdsRadius.button),
          side: states.contains(WidgetState.focused)
              ? const BorderSide(color: LdsColors.primary, width: 2)
              : BorderSide.none,
        ),
      ),
    ),
  );
}
