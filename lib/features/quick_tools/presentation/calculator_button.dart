import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../shared/lds_colors.dart";
import "../../../shared/widgets/lds/lds.dart";
import "../domain/calculator.dart";

/// 계산기 값. 창을 닫았다 열어도 적던 계산이 남습니다(새로고침하면 지워짐).
final calculatorProvider = NotifierProvider<CalculatorNotifier, Calculator>(
  CalculatorNotifier.new,
);

class CalculatorNotifier extends Notifier<Calculator> {
  @override
  Calculator build() => const Calculator();

  void apply(Calculator Function(Calculator) change) => state = change(state);
}

/// 상단 바 계산기 단추: 누르면 단추 오른쪽 끝에 맞춘 팝오버(폭 280)에
/// 사칙연산 계산기. 자판으로도 적을 수 있고 Esc·바깥 누르기로 닫습니다.
class CalculatorButton extends StatelessWidget {
  const CalculatorButton({super.key});

  @override
  Widget build(BuildContext context) => LdsIconButton(
    icon: Icons.calculate_outlined,
    tooltip: "계산기",
    onPressed: () => Navigator.of(context).push(
      LdsPopoverRoute<void>(
        anchor: LdsPopoverRoute.anchorOf(context),
        label: "계산기 닫기",
        child: const CalculatorPanel(),
      ),
    ),
  );
}

class CalculatorPanel extends ConsumerStatefulWidget {
  const CalculatorPanel({super.key});

  static const width = 280.0;

  /// 큰 값 글자(테스트에서 찾습니다).
  static const displayKey = ValueKey("calculator-display");

  @override
  ConsumerState<CalculatorPanel> createState() => _CalculatorPanelState();
}

class _CalculatorPanelState extends ConsumerState<CalculatorPanel> {
  final _focus = FocusNode(debugLabel: "calculator");
  bool _copied = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _apply(Calculator Function(Calculator) change) {
    ref.read(calculatorProvider.notifier).apply(change);
    if (_copied) setState(() => _copied = false);
    // 단추를 눌러도 자판 입력이 이어지게 초점을 돌려 둡니다.
    _focus.requestFocus();
  }

  Future<void> _copy() async {
    final text = ref.read(calculatorProvider).copyText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _copied = true);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      // Ctrl/⌘+C는 결과 복사.
      if (!keys.isAltPressed && key == LogicalKeyboardKey.keyC) {
        _copy();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    Calculator Function(Calculator)? change;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      change = (c) => c.equals();
    } else if (key == LogicalKeyboardKey.backspace) {
      change = (c) => c.backspace();
    } else if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.keyC) {
      // 한글 입력 상태에서도 C(ㅊ)·X(ㅌ) 자리 글쇠가 듣게 글쇠로도 봅니다.
      change = (_) => const Calculator();
    } else if (key == LogicalKeyboardKey.keyX) {
      change = (c) => c.op(CalcOp.multiply);
    } else {
      final character = event.character;
      change = switch (character) {
        null => null,
        "+" => (c) => c.op(CalcOp.add),
        "-" => (c) => c.op(CalcOp.subtract),
        "*" || "x" || "X" => (c) => c.op(CalcOp.multiply),
        "/" => (c) => c.op(CalcOp.divide),
        "=" => (c) => c.equals(),
        "." => (c) => c.dot(),
        "%" => (c) => c.percent(),
        "c" || "C" => (_) => const Calculator(),
        _ when RegExp(r"^[0-9]$").hasMatch(character) => (c) => c.digit(
          character,
        ),
        _ => null,
      };
    }
    if (change == null) return KeyEventResult.ignored;
    _apply(change);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final calc = ref.watch(calculatorProvider);
    Widget digit(String d) =>
        _Key(text: d, label: d, onTap: () => _apply((c) => c.digit(d)));
    Widget op(CalcOp o) => _Key(
      text: o.symbol,
      label: o.label,
      tone: _KeyTone.soft,
      onTap: () => _apply((c) => c.op(o)),
    );
    final rows = [
      [
        _Key(
          text: "C",
          label: "모두 지우기",
          tone: _KeyTone.soft,
          onTap: () => _apply((_) => const Calculator()),
        ),
        _Key(
          icon: Icons.backspace_outlined,
          label: "한 글자 지우기",
          tone: _KeyTone.soft,
          onTap: () => _apply((c) => c.backspace()),
        ),
        _Key(
          text: "%",
          label: "퍼센트",
          tone: _KeyTone.soft,
          onTap: () => _apply((c) => c.percent()),
        ),
        op(CalcOp.divide),
      ],
      [digit("7"), digit("8"), digit("9"), op(CalcOp.multiply)],
      [digit("4"), digit("5"), digit("6"), op(CalcOp.subtract)],
      [digit("1"), digit("2"), digit("3"), op(CalcOp.add)],
      [
        _Key(
          text: "±",
          label: "부호 바꾸기",
          onTap: () => _apply((c) => c.negate()),
        ),
        digit("0"),
        _Key(text: ".", label: "소수점", onTap: () => _apply((c) => c.dot())),
        _Key(
          text: "=",
          label: "계산",
          tone: _KeyTone.primary,
          onTap: () => _apply((c) => c.equals()),
        ),
      ],
    ];
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: "계산기",
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: SizedBox(
          width: CalculatorPanel.width,
          // 창이 낮으면 넘치지 않고 스크롤합니다.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "계산기",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LdsColors.ink,
                        ),
                      ),
                    ),
                    LdsButton(
                      label: _copied ? "복사했어요" : "결과 복사",
                      size: LdsButtonSize.small,
                      variant: LdsButtonVariant.ghostNeutral,
                      onPressed: calc.copyText == null ? null : _copy,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 18,
                  // 식이 길면 방금 적은 끝쪽이 보이게 오른쪽에 붙입니다.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      calc.expression,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdsColors.muted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 40,
                  child: Semantics(
                    liveRegion: true,
                    label: "값 ${calc.display}",
                    excludeSemantics: true,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        calc.display,
                        key: CalculatorPanel.displayKey,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: calc.error == null ? 30 : 18,
                          fontWeight: FontWeight.w700,
                          color: calc.error == null
                              ? LdsColors.ink
                              : LdsColors.errorText,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final (index, row) in rows.indexed) ...[
                  if (index > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (at, key) in row.indexed) ...[
                        if (at > 0) const SizedBox(width: 8),
                        Expanded(child: key),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyTone { plain, soft, primary }

/// 계산기 단추 한 칸: 높이 44, 모서리 8.
class _Key extends StatelessWidget {
  const _Key({
    this.text,
    this.icon,
    required this.label,
    required this.onTap,
    this.tone = _KeyTone.plain,
  });

  final String? text;
  final IconData? icon;

  /// 화면 낭독기용 이름.
  final String label;
  final VoidCallback onTap;
  final _KeyTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      _KeyTone.plain => (Colors.white, LdsColors.ink),
      _KeyTone.soft => (LdsColors.lineSoft, LdsColors.title),
      _KeyTone.primary => (LdsColors.primary, Colors.white),
    };
    final radius = BorderRadius.circular(LdsRadius.iconButton);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: tone == _KeyTone.plain
                ? LdsColors.borderStrong
                : Colors.transparent,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // 자판 입력용 초점을 단추가 가져가지 않게 합니다.
          canRequestFocus: false,
          child: SizedBox(
            height: 44,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 18, color: foreground)
                  : Text(
                      text!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
