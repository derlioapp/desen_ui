import 'dart:math' as math;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

class SectionIndexPage extends StatelessWidget {
  const SectionIndexPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Navigation',
    title: 'Section index',
    lead:
        'A column of letters beside a long sorted list, such as contacts, '
        'stations or countries. Tap a letter, or run a finger along the '
        'column, to jump the list to that section, as with the iOS list '
        'index or Android\'s fast scroller.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          DocText(
            'You give the sections, usually only the letters that have '
            'items, in the list\'s own order and alphabet: Turkish has Ç, Ğ, '
            'İ, Ö, Ş and Ü of its own. `onChanged` gets the section to jump '
            'to, and the list does the scrolling. `value` is the section '
            'the list shows now; update it as the list scrolls, and it is '
            'marked with the selection style.',
          ),
          Example(snippet: 'section-index-overview', child: _Demo()),
          DocText(
            'Jump rather than animate: a long animated scroll on every '
            'letter would lag behind the finger, and the platform indexes '
            'jump too.',
          ),
        ],
      ),
      DocSection(
        title: 'The bubble',
        children: [
          DocText(
            'While a finger or the mouse button is down, a bubble beside the '
            'column shows the section under it, large enough to read past '
            'the finger. It sits on the side that faces the list: left in '
            'left-to-right layouts, right in right-to-left ones. It floats '
            'in the nearest `Overlay`, which `DsApp` provides.',
          ),
        ],
      ),
      DocSection(
        title: 'Fitting the letters',
        children: [
          DocText(
            'The column fills the height it is given and centers the '
            'letters in it. When they do not all fit, some give way to dots, '
            'evenly from the first to the last, as on iOS. A drag still '
            'reaches every section: the column\'s length is shared by all '
            'of them, not only the ones shown. Letters grow with the text '
            'size.',
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass `style` to one index, or put a `DsSectionIndexTheme` '
            'around part of the app. Each letter resolves for its own '
            'states: `selected` is the current section, `hovered` the '
            'letter under the mouse, `pressed` the one under the finger.',
          ),
          CodeBlock(
            'DsSectionIndex(\n'
            '  sections: letters,\n'
            '  value: current,\n'
            '  onChanged: jumpTo,\n'
            '  style: DsSectionIndexStyle(\n'
            '    color: muted,\n'
            '    bubbleSize: 64,\n'
            '  ),\n'
            ')',
          ),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves focus into the column and out again.'),
            ('Down / Up', 'Jumps to the next or previous section.'),
            ('Home / End', 'Jumps to the first or last section.'),
            ('A letter', 'Jumps to the first section that starts with it.'),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Screen readers get one adjustable control, named "Section '
                'index" in the app\'s language unless `semanticLabel` names '
                'it. Swiping up or down steps through the sections, and the '
                'current one is read as its value.',
            'A tap or a drag ticks once per section as the platform\'s '
                'selection haptic; keys and screen readers change it '
                'silently.',
            'The column is at least the theme\'s tap target wide: 24px on '
                'desktop, 44px on iOS and Android.',
            'The sections are shown as given; write them in capitals '
                'yourself if you want them.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('DsSectionIndex'),
          ApiTable([
            (
              'sections',
              'List<String>',
              'The sections, top to bottom, shown as given.',
            ),
            (
              'value',
              'String?',
              'The section the list shows now; null marks none.',
            ),
            (
              'onChanged',
              'ValueChanged<String>?',
              'Called with the section to jump to, also on a tap on the '
                  'current one. Null disables the column.',
            ),
            (
              'semanticLabel',
              'String?',
              'Names the column for screen readers.',
            ),
            (
              'style',
              'DsSectionIndexStyle?',
              'Letters, marker, dots and bubble, per state.',
            ),
            ('focusNode', 'FocusNode?', 'Focus node; one is made if null.'),
            ('autofocus', 'bool', 'Takes focus when first built.'),
          ]),
        ],
      ),
    ],
  );
}

/// Turkey's provinces in Turkish order, with an index beside them.
class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  static final _provinces = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', //
    'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', //
    'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', //
    'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', //
    'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', //
    'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', //
    'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş', 'Karabük', //
    'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kilis', 'Kırıkkale', //
    'Kırklareli', 'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', //
    'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', //
    'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', //
    'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', //
    'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak', //
  ]..sort((a, b) => dsCompareText(a, b, language: 'tr'));

  static const _rowHeight = 36.0;

  final _controller = ScrollController();

  /// The first row of each letter, in order.
  late final _firstRow = <String, int>{
    for (var i = _provinces.length - 1; i >= 0; i--) _provinces[i][0]: i,
  };
  late final _letters = _firstRow.keys.toList()
    ..sort((a, b) => dsCompareText(a, b, language: 'tr'));

  String _current = 'A';

  @override
  void initState() {
    super.initState();
    // The section at the top of the list follows the scroll.
    _controller.addListener(() {
      final row = (_controller.offset / _rowHeight).floor().clamp(
        0,
        _provinces.length - 1,
      );
      final letter = _provinces[row][0];
      if (letter != _current) setState(() => _current = letter);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return SizedBox(
      width: 320,
      height: 360,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemExtent: _rowHeight,
              itemCount: _provinces.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _provinces[i],
                    style: t.typography.body.copyWith(color: t.colors.text),
                  ),
                ),
              ),
            ),
          ),
          // #region section-index-overview
          DsSectionIndex(
            sections: _letters,
            value: _current,
            semanticLabel: 'Provinces by letter',
            onChanged: (letter) => _controller.jumpTo(
              math.min(
                _firstRow[letter]! * _rowHeight,
                _controller.position.maxScrollExtent,
              ),
            ),
          ),
          // #endregion
        ],
      ),
    );
  }
}
