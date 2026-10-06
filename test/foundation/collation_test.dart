import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> sorted(List<String> words, String? language) =>
      [...words]..sort((a, b) => dsCompareText(a, b, language: language));

  test('Turkish letters follow their base letter', () {
    expect(
      sorted([
        'Zeytin',
        'Çiçek',
        'Cem',
        'Deniz',
        'Ömer',
        'Oya',
        'Şule',
        'Su',
      ], 'tr'),
      ['Cem', 'Çiçek', 'Deniz', 'Oya', 'Ömer', 'Su', 'Şule', 'Zeytin'],
    );
  });

  test('Turkish dotless ı sorts before i; I and İ lowercase apart', () {
    expect(sorted(['ilk', 'ışık', 'hız'], 'tr'), ['hız', 'ışık', 'ilk']);
    expect(sorted(['İzmir', 'Isparta', 'Hatay'], 'tr'), [
      'Hatay',
      'Isparta',
      'İzmir',
    ]);
  });

  test('elsewhere accents sort with the base letter, plain first', () {
    expect(sorted(['Zebra', 'Äpfel', 'Apfel', 'Bär'], 'de'), [
      'Apfel',
      'Äpfel',
      'Bär',
      'Zebra',
    ]);
    expect(sorted(['résumé', 'resume', 'rester'], 'fr'), [
      'rester',
      'resume',
      'résumé',
    ]);
    expect(dsCompareText('Straße', 'strasse', language: 'de'), greaterThan(0));
  });

  test('case is a last tie-break', () {
    expect(sorted(['b', 'B', 'a', 'A'], 'en'), ['a', 'A', 'b', 'B']);
  });

  testWidgets('a Turkish table sorts names in Turkish order', (tester) async {
    final names = ['Zeytin', 'Çiçek', 'Cem', 'Deniz'];
    await tester.pumpWidget(
      DsApp(
        locale: const Locale('tr'),
        home: DsTable<String>(
          rows: names,
          rowKey: (n) => n,
          sort: const DsTableSort('name'),
          columns: [
            DsTableColumn<String>(
              id: 'name',
              label: 'Ad',
              value: (n) => n,
              sortable: true,
            ),
          ],
        ),
      ),
    );
    final ys = {for (final n in names) n: tester.getTopLeft(find.text(n)).dy};
    expect(names.toList()..sort((a, b) => ys[a]!.compareTo(ys[b]!)), [
      'Cem',
      'Çiçek',
      'Deniz',
      'Zeytin',
    ]);
  });

  group('collation keys', () {
    // Letters that exercise every rule: Turkish letters, I/İ/ı, accents,
    // ligatures, case, a combining dot, non-Latin and an emoji.
    const alphabet = [
      'a',
      'A',
      'b',
      'c',
      'C',
      'ç',
      'Ç',
      'd',
      'e',
      'é',
      'É',
      'ë',
      'g',
      'ğ',
      'h',
      'ı',
      'I',
      'i',
      'İ',
      'o',
      'ö',
      'Ö',
      'ø',
      's',
      'ş',
      'Ş',
      'ß',
      'u',
      'ü',
      'z',
      'æ',
      'Œ',
      '̇',
      ' ',
      '1',
      '9',
      'σ',
      'Ж',
      '😀',
      '-',
    ];
    final words = [
      for (var i = 0; i < 600; i++)
        [
          for (var j = 0; j < 1 + (i * 7) % 6; j++)
            alphabet[(i * 31 + j * 17 + (i ~/ 5) * j) % alphabet.length],
        ].join(),
    ];

    for (final language in ['tr', 'de', null]) {
      test('agree with the per-letter reference ($language)', () {
        for (var i = 0; i < words.length; i++) {
          for (var j = 0; j < words.length; j += 7) {
            final a = words[i], b = words[j];
            final expected = _referenceCompare(a, b, language).sign;
            expect(
              dsCompareText(a, b, language: language).sign,
              expected,
              reason: '"$a" vs "$b"',
            );
            expect(
              DsCollationKey(
                a,
                language: language,
              ).compareTo(DsCollationKey(b, language: language)).sign,
              expected,
              reason: 'keys of "$a" vs "$b"',
            );
          }
        }
      });
    }

    test('sorting keys matches sorting with dsCompareText', () {
      final byCompare = [...words]
        ..sort((a, b) => dsCompareText(a, b, language: 'tr'));
      final byKeys = [for (final w in words) DsCollationKey(w, language: 'tr')]
        ..sort();
      expect([for (final k in byKeys) k.text], byCompare);
    });

    test('10,000 strings sort within a small multiple of plain compareTo', () {
      final names = [
        for (var i = 0; i < 10000; i++)
          'Müşteri ${(i * 7919) % 10000} Çağlar Şirketi',
      ];
      // Warm both paths up (JIT, letter cache).
      for (var r = 0; r < 2; r++) {
        [...names].sort();
        [for (final n in names) DsCollationKey(n, language: 'tr')].sort();
      }
      int best(void Function() run) {
        var min = 1 << 30;
        for (var r = 0; r < 3; r++) {
          final sw = Stopwatch()..start();
          run();
          min = sw.elapsedMicroseconds < min ? sw.elapsedMicroseconds : min;
        }
        return min;
      }

      final plain = best(() => [...names].sort());
      final keyed = best(
        () =>
            [for (final n in names) DsCollationKey(n, language: 'tr')]..sort(),
      );
      // Measured about 4-8× in test mode; it was about 190× when every
      // comparison read both strings letter by letter.
      expect(
        keyed,
        lessThan(plain * 30 + 20000),
        reason: '$keyed vs $plain µs',
      );
      // Comparing directly reads the letters as it goes: about 6× in test
      // mode.
      final direct = best(
        () => [...names]..sort((a, b) => dsCompareText(a, b, language: 'tr')),
      );
      expect(
        direct,
        lessThan(plain * 40 + 20000),
        reason: '$direct vs $plain µs',
      );
    });
  });
}

// The collation as first written (one string per letter, every
// comparison): the reference the cached keys must agree with.
int _referenceCompare(String a, String b, String? language) {
  final turkic = language == 'tr' || language == 'az';
  final ka = _referenceKey(a, turkic), kb = _referenceKey(b, turkic);
  for (var level = 0; level < 3; level++) {
    final x = ka[level], y = kb[level];
    final n = x.length < y.length ? x.length : y.length;
    for (var i = 0; i < n; i++) {
      if (x[i] != y[i]) return x[i] - y[i];
    }
    if (x.length != y.length) return x.length - y.length;
  }
  return a.compareTo(b);
}

List<List<int>> _referenceKey(String s, bool turkic) {
  const turkicAfter = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'h',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  };
  const groups = {
    'a': 'àáâãäåāăą',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįı',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľŀł',
    'n': 'ñńņňŉ',
    'o': 'òóôõöøōŏő',
    'r': 'ŕŗř',
    's': 'śŝşšș',
    't': 'ţťŧț',
    'u': 'ùúûüũūŭůűų',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
  };
  final accents = groups.values.join();
  final baseLetter = {
    for (final MapEntry(key: base, value: accented) in groups.entries)
      for (final c in accented.split('')) c: base,
  };
  String expand(String c) => switch (c) {
    'ß' => 'ss',
    'æ' => 'ae',
    'œ' => 'oe',
    _ => c,
  };
  final primary = <int>[], secondary = <int>[], tertiary = <int>[];
  for (final rune in s.runes) {
    var ch = String.fromCharCode(rune);
    final upper = ch != ch.toLowerCase();
    if (turkic) {
      if (ch == 'I') ch = 'ı';
      if (ch == 'İ') ch = 'i';
    }
    ch = ch.toLowerCase().replaceAll('̇', '');
    for (final unit in expand(ch).runes) {
      final c = String.fromCharCode(unit);
      final turkicLetter = turkic ? turkicAfter[c] : null;
      if (turkicLetter != null) {
        primary.add(turkicLetter.codeUnitAt(0) * 4 + 2);
        secondary.add(0);
      } else {
        final base = baseLetter[c];
        primary.add((base ?? c).codeUnitAt(0) * 4);
        secondary.add(base == null ? 0 : 1 + accents.indexOf(c));
      }
      tertiary.add(upper ? 1 : 0);
    }
  }
  return [primary, secondary, tertiary];
}
