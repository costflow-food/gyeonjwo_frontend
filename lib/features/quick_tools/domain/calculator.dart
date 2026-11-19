/// 사칙연산 기호.
enum CalcOp {
  add("+", "더하기"),
  subtract("−", "빼기"),
  multiply("×", "곱하기"),
  divide("÷", "나누기");

  const CalcOp(this.symbol, this.label);

  final String symbol;

  /// 화면 낭독기용 이름.
  final String label;
}

/// 상단 바 계산기의 상태. 단추를 누를 때마다 새 상태를 돌려줍니다.
///
/// 식을 끝까지 적고 '='을 누르면 곱셈·나눗셈을 먼저 계산합니다
/// (`2 + 3 × 4 = 14`).
class Calculator {
  const Calculator({
    this.terms = const [],
    this.ops = const [],
    this.input = "",
    this.history = "",
    this.error,
    this.evaluated = false,
    this.value,
  });

  /// 한 숫자에 넣을 수 있는 자릿수.
  static const maxDigits = 15;

  /// 이미 적은 숫자들. [ops]와 길이가 같습니다(숫자 뒤에 기호가 하나씩).
  final List<double> terms;
  final List<CalcOp> ops;

  /// 지금 적는 숫자(예: `-12.5`). 아직 안 적었으면 빈 글자.
  final String input;

  /// '='을 누른 뒤 위에 보여 줄 식(예: `1,200 × 3 =`).
  final String history;

  /// 계산할 수 없을 때 숫자 대신 보여 줄 말.
  final String? error;

  /// [input]이 계산해서 나온 값입니다('='·'%' 뒤). 이어 적지 않고, 숫자를
  /// 누르면 새 계산을 시작합니다.
  final bool evaluated;

  /// [evaluated]일 때 반올림하기 전 값. 이어서 계산할 때 씁니다
  /// (`1 ÷ 3 = × 3 =`이 1이 되게).
  final double? value;

  /// 계산에 쓸 지금 숫자.
  double get _current => evaluated && value != null ? value! : _parse(input);

  /// 큰 글자로 보여 줄 값(천 단위 쉼표).
  String get display =>
      error ??
      formatNumber(
        input.isNotEmpty
            ? input
            : terms.isEmpty
            ? "0"
            : _raw(terms.last),
      );

  /// 값 위에 작게 보여 줄 식.
  String get expression => history.isNotEmpty
      ? history
      : [
          for (var i = 0; i < terms.length; i++)
            "${formatNumber(_raw(terms[i]))} ${ops[i].symbol}",
        ].join(" ");

  /// 복사할 값(쉼표 없음). 오류면 null.
  String? get copyText {
    if (error != null) return null;
    if (input.isEmpty) return terms.isEmpty ? "0" : _raw(terms.last);
    // 적은 그대로(화면에 보이는 값과 같게), 끝의 소수점만 뗍니다.
    final typed = input.endsWith(".")
        ? input.substring(0, input.length - 1)
        : input;
    return typed == "-0" ? "0" : typed;
  }

  /// 계산해 나온 값 뒤에 숫자를 적으면 그 값을 버리고 새 숫자를 시작합니다
  /// (`5 + 50 %` 뒤라면 `5 +`는 남깁니다).
  Calculator get _fresh => error != null
      ? const Calculator()
      : evaluated
      ? Calculator(terms: terms, ops: ops)
      : this;

  Calculator _with({List<double>? terms, List<CalcOp>? ops, String? input}) =>
      Calculator(
        terms: terms ?? this.terms,
        ops: ops ?? this.ops,
        input: input ?? this.input,
      );

  /// 숫자 단추(`0`~`9`).
  Calculator digit(String digit) {
    final base = _fresh;
    final current = base.input;
    if (current == "0") return base._with(input: digit);
    if (current == "-0") return base._with(input: "-$digit");
    final digits = current.replaceAll(RegExp(r"[^0-9]"), "").length;
    if (digits >= maxDigits) return base;
    return base._with(input: "$current$digit");
  }

  /// 소수점.
  Calculator dot() {
    final base = _fresh;
    if (base.input.contains(".")) return base;
    return base._with(input: base.input.isEmpty ? "0." : "${base.input}.");
  }

  /// 사칙연산 기호. 숫자 없이 다시 누르면 앞의 기호를 바꿉니다.
  Calculator op(CalcOp op) {
    if (error != null) return this;
    if (input.isEmpty) {
      if (terms.isEmpty) return _with(terms: [0], ops: [op]);
      return _with(ops: [...ops.take(ops.length - 1), op]);
    }
    return Calculator(terms: [...terms, _current], ops: [...ops, op]);
  }

  /// '='. 곱셈·나눗셈 먼저, 그다음 덧셈·뺄셈.
  Calculator equals() {
    if (error != null || ops.isEmpty) return this;
    final numbers = [...terms, if (input.isNotEmpty) _current];
    // 기호로 끝났으면 마지막 기호는 버립니다.
    final operators = ops.take(numbers.length - 1).toList();
    final text = [
      formatNumber(_raw(numbers.first)),
      for (var i = 0; i < operators.length; i++)
        "${operators[i].symbol} ${formatNumber(_raw(numbers[i + 1]))}",
      "=",
    ].join(" ");
    final sums = [numbers.first];
    final signs = <double>[1];
    for (var i = 0; i < operators.length; i++) {
      final next = numbers[i + 1];
      switch (operators[i]) {
        case CalcOp.multiply:
          sums.last *= next;
        case CalcOp.divide:
          if (next == 0) {
            return Calculator(error: "0으로 나눌 수 없어요", history: text);
          }
          sums.last /= next;
        case CalcOp.add:
          sums.add(next);
          signs.add(1);
        case CalcOp.subtract:
          sums.add(next);
          signs.add(-1);
      }
    }
    var result = 0.0;
    for (var i = 0; i < sums.length; i++) {
      result += signs[i] * sums[i];
    }
    if (!result.isFinite || result.abs() >= 1e21) {
      return Calculator(error: "숫자가 너무 커요", history: text);
    }
    return Calculator(
      input: _raw(result),
      history: text,
      evaluated: true,
      value: result,
    );
  }

  /// 지금 숫자를 100으로 나눕니다.
  Calculator percent() {
    if (error != null || input.isEmpty) return this;
    final result = _current / 100;
    return Calculator(
      terms: terms,
      ops: ops,
      input: _raw(result),
      evaluated: true,
      value: result,
    );
  }

  /// 지금 숫자의 부호를 바꿉니다.
  Calculator negate() {
    if (error != null || input.isEmpty || _current == 0) return this;
    final flipped = input.startsWith("-") ? input.substring(1) : "-$input";
    if (!evaluated) return _with(input: flipped);
    return Calculator(
      terms: terms,
      ops: ops,
      input: flipped,
      evaluated: true,
      value: value == null ? null : -value!,
    );
  }

  /// 마지막 한 글자를 지웁니다. 결과는 지우지 않습니다.
  Calculator backspace() {
    if (error != null) return const Calculator();
    if (evaluated || input.isEmpty) return this;
    final rest = input.substring(0, input.length - 1);
    return _with(input: rest == "-" ? "" : rest);
  }

  static double _parse(String input) =>
      double.parse(input.endsWith(".") ? "${input}0" : input);

  /// 계산 오차(0.1 + 0.2)를 지우려고 유효 숫자 15자리로 맞춘 글자. 지수
  /// 표기(`1e-7`) 없이 풀어 씁니다.
  static String _raw(double value) {
    final rounded = double.parse(value.toStringAsPrecision(15));
    if (rounded == 0) return "0";
    return _plain(rounded.toString());
  }

  /// `1e-7` → `0.0000001`, `1.5e+16` → `15000000000000000`, `12.0` → `12`.
  static String _plain(String text) {
    final negative = text.startsWith("-");
    final body = negative ? text.substring(1) : text;
    final at = body.indexOf("e");
    final mantissa = at == -1 ? body : body.substring(0, at);
    final exponent = at == -1 ? 0 : int.parse(body.substring(at + 1));
    final dot = mantissa.indexOf(".");
    final digits = mantissa.replaceFirst(".", "");
    // 소수점이 놓일 자리(왼쪽에서 몇 번째 숫자 뒤).
    final point = (dot == -1 ? mantissa.length : dot) + exponent;
    final String whole;
    var fraction = "";
    if (point <= 0) {
      whole = "0";
      fraction = "${"0" * -point}$digits";
    } else if (point >= digits.length) {
      whole = "$digits${"0" * (point - digits.length)}";
    } else {
      whole = digits.substring(0, point);
      fraction = digits.substring(point);
    }
    fraction = fraction.replaceFirst(RegExp(r"0+$"), "");
    return "${negative ? "-" : ""}$whole${fraction.isEmpty ? "" : ".$fraction"}";
  }

  /// 정수 부분에 천 단위 쉼표. 적는 중인 `12.`·`0.50`은 그대로 둡니다.
  static String formatNumber(String raw) {
    final negative = raw.startsWith("-");
    final body = negative ? raw.substring(1) : raw;
    final dot = body.indexOf(".");
    final whole = dot == -1 ? body : body.substring(0, dot);
    final rest = dot == -1 ? "" : body.substring(dot);
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(",");
      grouped.write(whole[i]);
    }
    return "${negative ? "-" : ""}$grouped$rest";
  }
}
