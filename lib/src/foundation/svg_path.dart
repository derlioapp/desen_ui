import 'package:flutter/painting.dart';

/// Parses SVG path data (the `d` attribute) into a [Path].
///
/// Supports every path command (M L H V C S Q T A Z, absolute and relative).
/// Arcs map directly onto [Path.arcToPoint], which follows SVG semantics.
Path dsParseSvgPath(String d) => _SvgPathParser(d).parse();

class _SvgPathParser {
  _SvgPathParser(this._d);

  final String _d;
  int _i = 0;

  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';

  static final _number = RegExp(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?');

  bool get _atEnd {
    _skipSeparators();
    return _i >= _d.length;
  }

  void _skipSeparators() {
    while (_i < _d.length) {
      final c = _d.codeUnitAt(_i);
      // space, tab, newline, carriage return, comma
      if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0x2C) {
        _i++;
      } else {
        break;
      }
    }
  }

  double _num() {
    _skipSeparators();
    final m = _number.matchAsPrefix(_d, _i);
    if (m == null) throw FormatException('Expected a number', _d, _i);
    _i = m.end;
    return double.parse(m[0]!);
  }

  /// Arc flags may be written without separators ("a1 1 0 01 1 1").
  bool _flag() {
    _skipSeparators();
    final c = _d[_i++];
    if (c != '0' && c != '1') {
      throw FormatException('Expected a flag', _d, _i - 1);
    }
    return c == '1';
  }

  Path parse() {
    final path = Path();
    var cur = Offset.zero, start = Offset.zero;
    Offset? lastCubic, lastQuad; // reflected control points for S and T
    String? cmd;

    while (!_atEnd) {
      final c = _d[_i];
      if (_commands.contains(c)) {
        cmd = c;
        _i++;
      } else if (cmd == null) {
        throw FormatException('Path must start with a command', _d, _i);
      } else if (cmd == 'M') {
        cmd = 'L'; // extra pairs after a moveto are linetos
      } else if (cmd == 'm') {
        cmd = 'l';
      }

      final rel = cmd.toLowerCase() == cmd;
      Offset pt(double x, double y) => rel ? cur + Offset(x, y) : Offset(x, y);
      Offset? cubicCtrl, quadCtrl;

      switch (cmd.toUpperCase()) {
        case 'M':
          cur = start = pt(_num(), _num());
          path.moveTo(cur.dx, cur.dy);
        case 'L':
          cur = pt(_num(), _num());
          path.lineTo(cur.dx, cur.dy);
        case 'H':
          final x = _num();
          cur = Offset(rel ? cur.dx + x : x, cur.dy);
          path.lineTo(cur.dx, cur.dy);
        case 'V':
          final y = _num();
          cur = Offset(cur.dx, rel ? cur.dy + y : y);
          path.lineTo(cur.dx, cur.dy);
        case 'C':
          final c1 = pt(_num(), _num()),
              c2 = pt(_num(), _num()),
              end = pt(_num(), _num());
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          cubicCtrl = c2;
          cur = end;
        case 'S':
          final c1 = lastCubic != null ? cur * 2 - lastCubic : cur;
          final c2 = pt(_num(), _num()), end = pt(_num(), _num());
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          cubicCtrl = c2;
          cur = end;
        case 'Q':
          final q = pt(_num(), _num()), end = pt(_num(), _num());
          path.quadraticBezierTo(q.dx, q.dy, end.dx, end.dy);
          quadCtrl = q;
          cur = end;
        case 'T':
          final q = lastQuad != null ? cur * 2 - lastQuad : cur;
          final end = pt(_num(), _num());
          path.quadraticBezierTo(q.dx, q.dy, end.dx, end.dy);
          quadCtrl = q;
          cur = end;
        case 'A':
          final rx = _num(), ry = _num(), rotation = _num();
          final large = _flag(), sweep = _flag();
          final end = pt(_num(), _num());
          path.arcToPoint(
            end,
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: large,
            clockwise: sweep,
          );
          cur = end;
        case 'Z':
          path.close();
          cur = start;
      }
      lastCubic = cubicCtrl;
      lastQuad = quadCtrl;
    }
    return path;
  }
}
