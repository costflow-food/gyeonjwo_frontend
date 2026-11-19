import "package:flutter_test/flutter_test.dart";
import "package:gyeonjwo_frontend/features/quick_tools/domain/calculator.dart";

/// `"12+3="`처럼 단추를 차례로 누릅니다. `x`·`/`·`-`는 곱하기·나누기·빼기,
/// `%` 퍼센트, `n` 부호, `<` 한 글자 지우기.
Calculator _press(String keys, [Calculator start = const Calculator()]) {
  var calc = start;
  for (final key in keys.split("")) {
    calc = switch (key) {
      "+" => calc.op(CalcOp.add),
      "-" => calc.op(CalcOp.subtract),
      "x" => calc.op(CalcOp.multiply),
      "/" => calc.op(CalcOp.divide),
      "=" => calc.equals(),
      "." => calc.dot(),
      "%" => calc.percent(),
      "n" => calc.negate(),
      "<" => calc.backspace(),
      _ => calc.digit(key),
    };
  }
  return calc;
}

void main() {
  test("처음은 0, 숫자를 적으면 천 단위 쉼표", () {
    expect(const Calculator().display, "0");
    expect(_press("1234567").display, "1,234,567");
    expect(_press("007").display, "7");
    expect(_press("12.50").display, "12.50");
    expect(_press(".5").display, "0.5");
    expect(_press("1..2").display, "1.2");
  });

  test("곱셈·나눗셈을 덧셈·뺄셈보다 먼저", () {
    expect(_press("2+3x4=").display, "14");
    expect(_press("2+3x4=").expression, "2 + 3 × 4 =");
    expect(_press("10-6/3=").display, "8");
    expect(_press("1200x3=").display, "3,600");
  });

  test("소수 계산 오차를 지웁니다", () {
    expect(_press("0.1+0.2=").display, "0.3");
    expect(_press("10/3=").display, "3.33333333333333");
    expect(_press("1/3=x3=").display, "1");
    expect(_press("0.07x100=").display, "7");
    expect(_press("1.1x1.1=").display, "1.21");
  });

  test("결과에 이어서 계산, 숫자를 누르면 새 계산", () {
    expect(_press("2+3=x4=").display, "20");
    final next = _press("2+3=7");
    expect(next.display, "7");
    expect(next.expression, "");
  });

  test("기호를 이어 누르면 바꾸고, 기호로 끝나면 그 기호는 버립니다", () {
    expect(_press("8+x2=").display, "16");
    expect(_press("8+=").display, "8");
    expect(_press("5+").expression, "5 +");
    expect(_press("5+").display, "5");
    expect(_press("-3=").display, "-3");
  });

  test("0으로 나누면 안내, 그 뒤 숫자를 누르면 새로 시작", () {
    final error = _press("5/0=");
    expect(error.display, "0으로 나눌 수 없어요");
    expect(error.copyText, isNull);
    expect(_press("+", error).display, "0으로 나눌 수 없어요");
    expect(_press("9", error).display, "9");
  });

  test("퍼센트·부호·지우기", () {
    expect(_press("50%").display, "0.5");
    expect(_press("200x15%=").display, "30");
    expect(_press("12n").display, "-12");
    expect(_press("12nn").display, "12");
    expect(_press("0n").display, "0");
    expect(_press("123<").display, "12");
    expect(_press("1<").display, "0");
    expect(_press("5n<").display, "0");
    expect(_press("2+3=<").display, "5");
  });

  test("계산해 나온 값은 이어 적지 않습니다", () {
    // 퍼센트 뒤 숫자는 새 숫자, 앞의 식은 남습니다.
    expect(_press("50%3").display, "3");
    expect(_press("5+50%").expression, "5 +");
    expect(_press("5+50%2=").display, "7");
    expect(_press("50%<").display, "0.5");
    // 아주 작은 값도 지수 표기 없이, 이어 눌러도 멈추지 않습니다.
    final tiny = _press("0.00001%");
    expect(tiny.display, "0.0000001");
    expect(_press("<", tiny).display, "0.0000001");
    expect(_press(".", tiny).display, "0.");
    expect(_press("5", tiny).display, "5");
    expect(_press("+1=", tiny).display, "1.0000001");
    expect(_press("n", tiny).copyText, "-0.0000001");
    // 결과에 % · ±를 누르면 위의 식은 지웁니다.
    expect(_press("200x3=%").expression, "");
    expect(_press("200x3=%").display, "6");
    expect(_press("2+3=n").display, "-5");
    expect(_press("2+3=n+1=").display, "-4");
  });

  test("큰 숫자: 15자리까지 그대로, 너무 크면 안내", () {
    expect(_press("1234567890123+1=").display, "1,234,567,890,124");
    expect(_press("123456789012345+").expression, "123,456,789,012,345 +");
    expect(_press("123456789012345").copyText, "123456789012345");
    expect(_press("9.99999999999999").copyText, "9.99999999999999");
    expect(_press("999999999999999x10=").display, "9,999,999,999,999,990");
    var huge = _press("999999999999999x999999999999999=");
    expect(huge.display, "숫자가 너무 커요");
    huge = _press("9", huge);
    expect(huge.display, "9");
  });

  test("자릿수 제한과 복사할 값", () {
    expect(_press("12345678901234567890").display, "123,456,789,012,345");
    expect(_press("1234.5").copyText, "1234.5");
    expect(_press("1200x3=").copyText, "3600");
    expect(_press("12.").copyText, "12");
  });
}
