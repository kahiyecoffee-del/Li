import 'dart:math' as math;

import 'quantities.dart';

/// Safe arithmetic evaluator for the calculator and for typed sums such as
/// "1250*12" or "(450 + 380) / 3". Supports + - × ÷ ^, parentheses, unary
/// minus and postfix % (divide by 100). Numbers accept "1.250,50" and
/// "1,250.50". Never uses eval.
abstract final class Calculator {
  static final _allowed = RegExp(r'^[\d\s.,+\-*/x×÷^()%]+$');

  /// Evaluates [input] if it is only arithmetic with at least one operator;
  /// trailing "=", "?", "kaç", "eder" are ignored.
  static double? tryEvaluate(String input) {
    var s = Quantities.fold(input).trim();
    s = s.replaceAll(RegExp(r'(\s*(=|\?|kac|eder|nedir|what is|is|how much)\s*)+$'), '');
    s = s.replaceAll(RegExp(r'^(what is|hesapla|calculate)\s+'), '');
    if (s.isEmpty || !_allowed.hasMatch(s)) return null;
    if (!RegExp(r'\d\s*[+\-*/x×÷^]\s*[\d(]|\)\s*[+\-*/x×÷^]|\d\s*%\s*$').hasMatch(s)) return null;
    try {
      final v = evaluate(s);
      return v.isFinite ? v : null;
    } on FormatException {
      return null;
    }
  }

  /// Throws [FormatException] on malformed input. With [dotDecimal] (the
  /// keypad), "." is always the decimal point; otherwise typed numbers are
  /// read the way people write them ("1.250" = 1250 in Turkish).
  static double evaluate(String expression, {bool dotDecimal = false}) {
    final p = _Parser(_tokens(expression), dotDecimal ? double.tryParse : Quantities.parseNumber);
    final v = p.expr();
    if (!p.done) throw const FormatException('Unexpected input');
    return v;
  }

  static List<String> _tokens(String s) {
    final out = <String>[];
    final re = RegExp(r'\d[\d.,]*|[+\-*/x×÷^()%]');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (s.substring(i, m.start).trim().isNotEmpty) throw const FormatException('Bad character');
      out.add(m.group(0)!);
      i = m.end;
    }
    if (s.substring(i).trim().isNotEmpty) throw const FormatException('Bad character');
    return out;
  }
}

class _Parser {
  _Parser(this.t, this.number);

  final List<String> t;
  final double? Function(String) number;
  var i = 0;

  bool get done => i >= t.length;
  String? get _peek => done ? null : t[i];

  double expr() {
    var v = term();
    while (_peek == '+' || _peek == '-') {
      final op = t[i++];
      final r = term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double term() {
    var v = unary();
    while (_peek == '*' || _peek == '/' || _peek == 'x' || _peek == '×' || _peek == '÷') {
      final op = t[i++];
      final r = unary();
      if (op == '/' || op == '÷') {
        if (r == 0) throw const FormatException('Division by zero');
        v = v / r;
      } else {
        v = v * r;
      }
    }
    return v;
  }

  // Unary minus binds looser than ^, so -3^2 = -9.
  double unary() {
    if (_peek == '-') {
      i++;
      return -unary();
    }
    if (_peek == '+') {
      i++;
      return unary();
    }
    return power();
  }

  double power() {
    final b = postfix();
    if (_peek == '^') {
      i++;
      return math.pow(b, unary()).toDouble();
    }
    return b;
  }

  double postfix() {
    var v = primary();
    while (_peek == '%') {
      i++;
      v = v / 100;
    }
    return v;
  }

  double primary() {
    final tok = _peek;
    if (tok == null) throw const FormatException('Unexpected end');
    if (tok == '(') {
      i++;
      final v = expr();
      if (_peek != ')') throw const FormatException('Missing )');
      i++;
      return v;
    }
    final n = number(tok);
    if (n == null) throw FormatException('Bad number $tok');
    i++;
    return n;
  }
}
