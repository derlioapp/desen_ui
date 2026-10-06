import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The search box: magnifier, query, clear button and shortcut hint.
class SearchFieldPage extends StatelessWidget {
  const SearchFieldPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Search field',
    lead:
        'A text field for queries: a magnifier, the query, a clear button '
        'once there is text, and an optional shortcut hint. Use it to search '
        'or filter what is on screen. An [autocomplete](/components/autocomplete) '
        'fits better for picking one value from a long list.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'search-field-overview',
            child: _Narrow(
              child: Column(
                spacing: 12,
                children: [
                  // #region search-field-overview
                  DsSearchField(placeholder: 'Search tasks, people or files'),
                  DsSearchField(initialValue: 'invoice template'),
                  // #endregion
                ],
              ),
            ),
          ),
          const DocText(
            'It is drawn as a control, like a secondary button, so it reads '
            'as a tool rather than a form question. The keyboard\'s action '
            'key reads "Search".',
          ),
        ],
      ),
      DocSection(
        title: 'Filtering',
        children: [
          const DocText(
            '`onChanged` follows every keystroke, and also the empty text '
            'when the query is cleared. Filter the list as people type; use '
            '`onSubmitted` when the search needs Enter, for example a server '
            'request.',
          ),
          Example(
            snippet: 'search-field-filter',
            alignment: AlignmentDirectional.topCenter,
            child: const _FilterDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Shortcut',
        children: [
          const DocText(
            '`shortcut` shows keys on a small chip while the field is '
            'empty. It only shows them: bind the keys yourself to focus the '
            'field. The hint is hidden on iOS and Android, where there is '
            'usually no keyboard.',
          ),
          const DocText(
            'This example listens to the keyboard app-wide, so the shortcut '
            'works wherever focus is. Press it, then Escape. (This site uses '
            '⌘K for its own search.)',
          ),
          const Example(
            snippet: 'search-field-shortcut',
            child: _Narrow(child: _ShortcutDemo()),
          ),
          const DocText(
            'A `CallbackShortcuts` around a part of the page works too, but '
            'only while focus is inside that part.',
          ),
        ],
      ),
      DocSection(
        title: 'Escape',
        children: [
          const DocText(
            'Escape clears the query and keeps focus. On an empty field, '
            'Escape goes on to the enclosing layer, so a search inside a '
            'dialog or popover closes it with a second press. While an input '
            'method is composing (Japanese, Chinese, Korean), Escape cancels '
            'only the composition. A `readOnly` search field is not cleared.',
          ),
          Example(
            snippet: 'search-field-escape',
            child: _Narrow(
              // #region search-field-escape
              child: DsSearchField(initialValue: 'design review'),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'A search field is the text field\'s `search` variant. Change one '
            'with `style`, or every search field through '
            '`DsTextFieldThemeData.variants`; the [text field](/components/text-field) '
            'page lists what a `DsTextFieldStyle` holds.',
          ),
          Example(
            snippet: 'search-field-custom',
            child: _Narrow(
              // #region search-field-custom
              child: DsTextFieldTheme(
                data: DsTextFieldThemeData(
                  variants: {
                    DsTextFieldVariant.search: DsTextFieldStyle(
                      borderRadius: BorderRadius.circular(999),
                      shadows: const [],
                    ),
                  },
                ),
                child: DsSearchField(placeholder: 'Search messages'),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('Tab', 'Moves focus to the field; the clear button is skipped.'),
            (
              'Escape',
              'Clears the query. On an empty field, closes the enclosing '
                  'dialog or popover.',
            ),
            ('Enter', 'Calls `onSubmitted` with the query.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a text field named "Search" in the app\'s language, '
                'unless `semanticLabel` or a `DsField` label names it.',
            'The placeholder is read as a hint. While the shortcut chip '
                'shows, its keys are read with the field.',
            'The clear button is a separate button named "Clear".',
            'Focus always shows, as on every text field.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'onChanged',
              'ValueChanged<String>?',
              'Called as the query changes, also when it is cleared.',
            ),
            (
              'onSubmitted',
              'ValueChanged<String>?',
              'Called on Enter or the keyboard\'s search key.',
            ),
            ('placeholder', 'String?', 'Shown while the field is empty.'),
            (
              'shortcut',
              'String?',
              'Keys shown while empty, such as "⌘K". Bind them yourself.',
            ),
            (
              'controller',
              'TextEditingController?',
              'Holds the query; one is created when null.',
            ),
            ('initialValue', 'String?', 'The starting query.'),
            (
              'focusNode',
              'FocusNode?',
              'Pass one to focus the field from a shortcut.',
            ),
            ('enabled', 'bool', 'Whether it can be focused and edited.'),
            (
              'readOnly',
              'bool',
              'A fixed query; Escape and the clear button leave it.',
            ),
            (
              'semanticLabel',
              'String?',
              'Defaults to "Search" when no `DsField` label names it.',
            ),
            ('style', 'DsTextFieldStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

/// Keeps a form-width example from stretching across the page.
class _Narrow extends StatelessWidget {
  const _Narrow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: child,
  );
}

class _FilterDemo extends StatefulWidget {
  const _FilterDemo();

  @override
  State<_FilterDemo> createState() => _FilterDemoState();
}

class _FilterDemoState extends State<_FilterDemo> {
  static const _tasks = [
    'Draft the Q3 roadmap',
    'Review the pricing page copy',
    'Fix the login redirect on Safari',
    'Plan the design review',
    'Update the invoice template',
    'Interview the backend candidate',
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final q = dsFoldCase(_query.trim());
    final shown = [
      for (final task in _tasks)
        if (dsFoldCase(task).contains(q)) task,
    ];
    return _Narrow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          // #region search-field-filter
          DsSearchField(
            placeholder: 'Filter tasks',
            onChanged: (v) => setState(() => _query = v),
          ),
          // #endregion
          // Room for every task, so the example keeps its height.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200),
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      'No tasks match "${_query.trim()}".',
                      style: t.typography.small.copyWith(
                        color: t.colors.textMuted,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final task in shown)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            task,
                            style: t.typography.body.copyWith(
                              color: t.colors.text,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutDemo extends StatefulWidget {
  const _ShortcutDemo();

  @override
  State<_ShortcutDemo> createState() => _ShortcutDemoState();
}

class _ShortcutDemoState extends State<_ShortcutDemo> {
  // #region search-field-shortcut
  // Ctrl+/ or ⌘/ focuses the search field, wherever focus is.
  final _search = FocusNode();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _search.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.slash &&
        (keys.isMetaPressed || keys.isControlPressed)) {
      _search.requestFocus();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final apple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return DsSearchField(
      focusNode: _search,
      placeholder: 'Search the handbook',
      shortcut: apple ? '⌘/' : 'Ctrl+/',
    );
  }

  // #endregion
}
