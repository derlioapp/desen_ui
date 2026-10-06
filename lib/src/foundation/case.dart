import 'package:flutter/foundation.dart';

/// Case folding for matching, never for display.
///
/// Search boxes and typeahead compare what someone typed with labels in
/// another case. `toLowerCase()` alone is not that comparison: it is
/// locale-independent and leaves gaps. This lowercases (Dart already maps
/// the Turkish `İ` to `i`) and closes the rest:
///
/// * `ı` (dotless i) folds onto `i`, so typing `ısparta` finds `Isparta`;
/// * a stray combining dot above (U+0307) after an `İ` is dropped;
/// * German `ß` folds to `ss`, so `Straße` meets `STRASSE`;
/// * Greek final sigma `ς` folds to `σ`.
///
/// Diacritics stay: `resume` does not match `résumé`; those are different
/// words, not different cases.
String dsFoldCase(String value) => value
    .toLowerCase()
    .replaceAll('̇', '')
    .replaceAll('ı', 'i')
    .replaceAll('ß', 'ss')
    .replaceAll('ς', 'σ');

/// Compares two strings in dictionary order for [language] (a language
/// code such as `'tr'`), for sorting lists and tables shown to people.
///
/// Not a full Unicode collation, but right for Latin-script languages:
///
/// * case is ignored first, then lowercase sorts before uppercase;
/// * accented letters sort with their base letter (`é` with `e`, German
///   `ä` with `a`), the plain letter first on a tie;
/// * in Turkish (`tr`, also `az`) `ç ğ ı ö ş ü` are letters of their own,
///   right after `c g h o s u` (`ı` before `i`), and `I`/`İ` lowercase to
///   `ı`/`i`: "Çiçek" sorts after "Cem" and before "Deniz", not after "Z".
///
/// Other scripts compare by code point after case folding.
///
/// Each call reads both strings letter by letter. To sort many strings,
/// make one [DsCollationKey] per string and sort the keys: the reading is
/// then done once per string instead of once per comparison.
int dsCompareText(String a, String b, {String? language}) {
  final turkic = _isTurkic(language);
  // Most pairs differ in their letters: compare those first, without
  // building keys, and only fall back to accents and case on a tie.
  var c = _comparePrimary(a, b, turkic);
  if (c != 0) return c;
  c = _compareWeights(_collationKey(a, turkic), _collationKey(b, turkic));
  return c != 0 ? c : a.compareTo(b);
}

final _noWeights = Int32List(0);

/// Compares the letters (primary weights) of [a] and [b] as their keys
/// would, reading both strings side by side.
int _comparePrimary(String a, String b, bool turkic) {
  final cache = turkic ? _turkicWeights : _otherWeights;
  var ia = 0, ib = 0, ja = 0, jb = 0;
  var wa = _noWeights, wb = _noWeights;
  while (true) {
    while (ja >= wa.length && ia < a.length) {
      final rune = _runeAt(a, ia);
      ia += rune > 0xFFFF ? 2 : 1;
      wa = _weightsOf(rune, cache, turkic);
      ja = 0;
    }
    while (jb >= wb.length && ib < b.length) {
      final rune = _runeAt(b, ib);
      ib += rune > 0xFFFF ? 2 : 1;
      wb = _weightsOf(rune, cache, turkic);
      jb = 0;
    }
    final endA = ja >= wa.length, endB = jb >= wb.length;
    if (endA || endB) return endA ? (endB ? 0 : -1) : 1;
    final d = wa[ja] - wb[jb];
    if (d != 0) return d;
    ja += 3;
    jb += 3;
  }
}

/// The letter at [i]: a surrogate pair is one letter.
int _runeAt(String s, int i) {
  final unit = s.codeUnitAt(i);
  if (unit & 0xFC00 == 0xD800 && i + 1 < s.length) {
    final low = s.codeUnitAt(i + 1);
    if (low & 0xFC00 == 0xDC00) {
      return 0x10000 + ((unit & 0x3FF) << 10) + (low & 0x3FF);
    }
  }
  return unit;
}

Int32List _weightsOf(int rune, _WeightCache cache, bool turkic) => rune < 0x80
    ? (cache.ascii[rune] ??= _runeWeights(rune, turkic))
    : (cache.other[rune] ??= _runeWeights(rune, turkic));

/// The sort key of [text] in [language]: keys compare as [dsCompareText]
/// compares their texts, but the letters are read once, when the key is
/// made.
///
/// ```dart
/// final keys = [for (final n in names) DsCollationKey(n, language: 'tr')]
///   ..sort();
/// final sorted = [for (final k in keys) k.text];
/// ```
///
/// Only compare keys made for the same language.
@immutable
final class DsCollationKey implements Comparable<DsCollationKey> {
  /// The key of [text] in [language] (a language code such as `'tr'`).
  DsCollationKey(this.text, {String? language})
    : _weights = _collationKey(text, _isTurkic(language));

  /// The text this key sorts.
  final String text;

  /// Primary, secondary and tertiary weights, each level ended by a zero.
  final Int32List _weights;

  @override
  int compareTo(DsCollationKey other) {
    final c = _compareWeights(_weights, other._weights);
    return c != 0 ? c : text.compareTo(other.text);
  }

  @override
  bool operator ==(Object other) =>
      other is DsCollationKey && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'DsCollationKey($text)';
}

bool _isTurkic(String? language) => language == 'tr' || language == 'az';

int _compareWeights(Int32List x, Int32List y) {
  final n = x.length < y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    final d = x[i] - y[i];
    if (d != 0) return d;
  }
  return x.length - y.length;
}

// Scratch space for one key's three levels, grown as needed. Keys are made
// one at a time, so one set serves every call.
Int32List _primary = Int32List(64);
Int32List _secondary = Int32List(64);
Int32List _tertiary = Int32List(64);

/// The primary (letter), secondary (accent) and tertiary (case) weights of
/// [s] in one list: each weight plus one, each level ended by a zero. So
/// comparing two lists element by element compares level by level, and a
/// string that begins another sorts first.
Int32List _collationKey(String s, bool turkic) {
  // A letter gives at most two weights (ß → ss).
  final room = s.length * 2;
  if (_primary.length < room) {
    _primary = Int32List(room);
    _secondary = Int32List(room);
    _tertiary = Int32List(room);
  }
  final cache = turkic ? _turkicWeights : _otherWeights;
  var n = 0;
  for (var i = 0; i < s.length;) {
    final rune = _runeAt(s, i);
    i += rune > 0xFFFF ? 2 : 1;
    final w = _weightsOf(rune, cache, turkic);
    for (var j = 0; j < w.length; j += 3) {
      _primary[n] = w[j];
      _secondary[n] = w[j + 1];
      _tertiary[n] = w[j + 2];
      n++;
    }
  }
  final key = Int32List(n * 3 + 2);
  for (var i = 0; i < n; i++) {
    key[i] = _primary[i] + 1;
    key[n + 1 + i] = _secondary[i] + 1;
    key[2 * n + 2 + i] = _tertiary[i] + 1;
  }
  return key;
}

/// Weights already worked out, per letter: a list for ASCII, a map for
/// the rest.
class _WeightCache {
  final ascii = List<Int32List?>.filled(0x80, null);
  final other = <int, Int32List>{};
}

final _otherWeights = _WeightCache();
final _turkicWeights = _WeightCache();

/// The weights of one letter as (primary, secondary, tertiary) triples.
/// Worked out once per letter and language family, then cached.
Int32List _runeWeights(int rune, bool turkic) {
  var ch = String.fromCharCode(rune);
  final upper = ch != ch.toLowerCase();
  if (turkic) {
    if (ch == 'I') ch = 'ı';
    if (ch == 'İ') ch = 'i';
  }
  ch = ch.toLowerCase().replaceAll('̇', '');
  final out = <int>[];
  for (final unit in _expand(ch).runes) {
    final c = String.fromCharCode(unit);
    final turkicLetter = turkic ? _turkicAfter[c] : null;
    if (turkicLetter != null) {
      out
        ..add(turkicLetter.codeUnitAt(0) * 4 + 2)
        ..add(0);
    } else {
      final base = _baseLetter[c];
      out
        ..add((base ?? c).codeUnitAt(0) * 4)
        ..add(base == null ? 0 : 1 + _accents.indexOf(c));
    }
    out.add(upper ? 1 : 0);
  }
  return Int32List.fromList(out);
}

/// Ligatures that sort as two letters.
String _expand(String c) => switch (c) {
  'ß' => 'ss',
  'æ' => 'ae',
  'œ' => 'oe',
  _ => c,
};

/// Turkish letters of their own, keyed to the letter they follow.
const _turkicAfter = {
  'ç': 'c',
  'ğ': 'g',
  'ı': 'h',
  'ö': 'o',
  'ş': 's',
  'ü': 'u',
};

const _accentGroups = {
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

final String _accents = _accentGroups.values.join();

final Map<String, String> _baseLetter = {
  for (final MapEntry(key: base, value: accented) in _accentGroups.entries)
    for (final c in accented.split('')) c: base,
};
