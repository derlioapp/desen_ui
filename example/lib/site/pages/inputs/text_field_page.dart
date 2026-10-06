import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';

/// Single- and multi-line text entry.
class TextFieldPage extends StatelessWidget {
  const TextFieldPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Inputs',
    title: 'Text field',
    lead:
        'Lets people type a short value on one line, or longer text on '
        'several. Use a [number field](/components/number-field) for '
        'numbers, a [search field](/components/search-field) for queries, '
        'and a [select](/components/select) when the answers are known.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'text-field-overview',
            child: _Narrow(
              // #region text-field-overview
              child: DsField(
                label: const Text('Work email'),
                child: DsTextField(
                  placeholder: 'name@company.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  leading: const DsIcon(DsIcons.mail),
                ),
              ),
              // #endregion
            ),
          ),
          const DocText(
            'The field fills the width it is given. In a `Row` or another '
            'unbounded width it is 240px wide, like an HTML input. Typing, '
            'input methods, autofill, selection and the keyboard shortcuts '
            'are Flutter\'s own, so they behave as each platform expects.',
          ),
        ],
      ),
      DocSection(
        title: 'Multi-line',
        children: [
          const DocText(
            '`DsTextField.multiline` starts `minLines` tall (3), grows with '
            'the text up to `maxLines` (8), then scrolls. Enter adds a line. '
            'There is no resize handle; growing with the text does that job '
            'on every platform.',
          ),
          Example(
            snippet: 'text-field-multiline',
            child: _Narrow(
              // #region text-field-multiline
              child: DsField(
                label: const Text('Description'),
                description: const Text('Markdown is supported.'),
                child: DsTextField.multiline(
                  placeholder: 'What should reviewers know?',
                  maxLines: 6,
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Leading and trailing',
        children: [
          const DocText(
            '`leading` goes before the text and `trailing` after it. Both '
            'take an icon or a short text such as a protocol or a domain, in '
            'the muted icon color.',
          ),
          const DocText(
            'A text in a slot is an affix and sits 4px from the value '
            '(`affixGap` in the style). On a single line, trailing text '
            'follows the typed text, or the placeholder while the field is '
            'empty, so ".desen.app" sits right after the name. In a '
            'multi-line field it stays at the end. Icons keep the wider '
            '`gap` (12px) and sit at the field\'s edges.',
          ),
          Example(
            snippet: 'text-field-slots',
            child: _Narrow(
              child: Column(
                spacing: 16,
                children: [
                  // #region text-field-slots
                  DsField(
                    label: const Text('Website'),
                    child: DsTextField(
                      initialValue: 'northwind.studio',
                      keyboardType: TextInputType.url,
                      leading: const Text('https://'),
                    ),
                  ),
                  DsField(
                    label: const Text('Workspace address'),
                    child: DsTextField(
                      initialValue: 'northwind',
                      trailing: const Text('.desen.app'),
                    ),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Clear and show password',
        children: [
          const DocText(
            '`clearable` adds a clear button while the field has text. '
            'Clearing keeps focus in the field and reports the empty text to '
            '`onChanged`. The button is not a Tab stop: select all and '
            'delete do the same from the keyboard.',
          ),
          const DocText(
            '`revealable` adds a show password button to an `obscureText` '
            'field; it is a Tab stop. Copy and cut are off while the text '
            'is hidden.',
          ),
          Example(
            snippet: 'text-field-buttons',
            child: _Narrow(
              child: Column(
                spacing: 16,
                children: [
                  // #region text-field-buttons
                  DsField(
                    label: const Text('Label'),
                    child: DsTextField(
                      initialValue: 'quarterly-review',
                      clearable: true,
                    ),
                  ),
                  DsField(
                    label: const Text('Password'),
                    description: const Text('At least 8 characters.'),
                    child: DsTextField(
                      initialValue: 'correct horse',
                      obscureText: true,
                      revealable: true,
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
          const DocText(
            'Both buttons keep a full tap target without making the field '
            'taller. The error icon, when there is one, comes after them.',
          ),
        ],
      ),
      DocSection(
        title: 'Character counter',
        children: [
          const DocText(
            'With `maxLength` a counter ("12 / 60") shows under the field, at '
            'the end of the `DsField` message row. The limit is enforced by '
            'default and counts characters as people do, so an emoji counts '
            'as one.',
          ),
          const DocText(
            'With `maxLengthEnforcement: MaxLengthEnforcement.none` it '
            'becomes a soft limit, as on GitHub: typing goes on, the counter '
            'turns to the danger color and the field shows its error look. Give the field an '
            'error message to say by how much.',
          ),
          Example(snippet: 'text-field-counter', child: const _CounterDemo()),
        ],
      ),
      DocSection(
        title: 'Read-only and disabled',
        children: [
          const DocText(
            'A `readOnly` field reads as a value on the page: no fill, a '
            'faint edge and text at full contrast. It still takes focus, '
            'and its text can be selected and copied. Use it for values '
            'people need to copy, like an ID.',
          ),
          const DocText(
            'A disabled field (`enabled: false`) keeps its shape in the '
            'dimmed disabled colors and is skipped by Tab. Say why in the '
            'description.',
          ),
          Example(
            snippet: 'text-field-readonly',
            child: _Narrow(
              child: Column(
                spacing: 16,
                children: [
                  // #region text-field-readonly
                  DsField(
                    label: const Text('Workspace ID'),
                    child: DsTextField(
                      initialValue: 'ws_7Hq2kL9xR4',
                      readOnly: true,
                    ),
                  ),
                  DsField(
                    label: const Text('Billing email'),
                    description: const Text('Managed by your organization.'),
                    child: DsTextField(
                      initialValue: 'billing@northwind.studio',
                      enabled: false,
                    ),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Error',
        children: [
          const DocText(
            'Inside a `DsField`, set its `errorText`: the field shows the '
            'message and the text field takes the error look. The error look '
            'is a 2px danger edge and an icon, not color alone. When focused, '
            'the edge shows focus while the icon and the message keep '
            'telling the error.',
          ),
          Example(snippet: 'text-field-error', child: const _ErrorDemo()),
          const DocText(
            'A text field on its own takes `error: true` and a '
            '`semanticLabel`. Put the message in text near it, since the '
            'edge alone does not explain anything.',
          ),
        ],
      ),
      const DocSection(
        title: 'Selection and the edit menu',
        children: [
          DocText(
            'With a mouse, a click places the caret, a drag selects, a double '
            'click selects a word and a triple click a paragraph; Shift+click '
            'extends. On touch, a tap places the caret and a long press '
            'selects a word. Handles in the caret color drag the ends: '
            'lollipops on iOS, teardrops elsewhere. While a handle is dragged '
            'or a long press selects, a loupe floats above the line and '
            'enlarges the text under the finger (`DsTextMagnifier`), on iOS '
            'and Android only. It grows in and shrinks away as the finger '
            'lifts; with reduced motion it only fades.',
          ),
          DocList([
            '**iOS:** the native edit menu where the system supports it, '
                'otherwise Desen\'s floating toolbar.',
            '**Android and touch screens on desktop:** Desen\'s floating '
                'toolbar, above the selection, or below it when there is no '
                'room.',
            '**Desktop apps:** a right click or Shift+F10 opens a Desen menu '
                'with Cut, Copy, Paste and Select all and their shortcuts. '
                'Actions that cannot run now are disabled.',
            '**Web:** the browser\'s own menu stays, with spellcheck, '
                'translate and autofill. This site keeps it, so a right click '
                'in the examples shows the browser menu.',
          ]),
          DocText(
            'To use Desen\'s menu on the web as well, turn the browser\'s off '
            'once at startup:',
          ),
          CodeBlock(
            'void main() {\n'
            '  BrowserContextMenu.disableContextMenu();\n'
            '  runApp(const App());\n'
            '}',
          ),
          Callout(
            'Menus, handles and the loupe need an `Overlay`, which `DsApp` '
            'provides. '
            'Without one the field still types, selects and copies with the '
            'keyboard.',
          ),
        ],
      ),
      DocSection(
        title: 'Spell check',
        children: [
          const DocText(
            'On iOS and Android a misspelled word gets the platform\'s '
            'underline in the danger color: dotted on iOS, wavy on Android. '
            'Tapping the word opens a toolbar like the edit menu with up to '
            'three replacements. Choosing one replaces the word and puts the '
            'caret after it.',
          ),
          const DocList([
            '**iOS:** the tapped word is selected on a danger tint. A word '
                'the checker has no replacement for shows a disabled "No '
                'replacements found".',
            '**Android:** the caret goes into the word, and a Delete action '
                'after the suggestions removes it.',
            '**Desktop and the web:** off. Flutter has a spell checker on '
                'iOS and Android only; on the web the browser\'s own menu '
                'stays, so these examples show no underline.',
          ]),
          const DocText(
            'It is on by default for prose: plain and multi-line text. It '
            'is off where the text must stay as typed or is not prose: '
            'email, URL, password, number, phone, date, name and address '
            'fields, search fields, and any field with `autocorrect: '
            'false`. `spellCheck` sets it either way.',
          ),
          Example(
            snippet: 'text-field-spell-check',
            child: _Narrow(
              child: Column(
                spacing: 16,
                children: [
                  // #region text-field-spell-check
                  DsField(
                    label: const Text('Release notes'),
                    // Prose: spell check is on by default on phones.
                    child: DsTextField.multiline(minLines: 2),
                  ),
                  DsField(
                    label: const Text('Project code'),
                    // Not a word: no underline, no suggestions.
                    child: DsTextField(spellCheck: false),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
          const DocText(
            'The underline is `misspelledStyle` in `DsTextFieldStyle`, and '
            'the iOS highlight `misspelledSelectionColor`. The toolbar is '
            '`DsSpellCheckSuggestionsToolbar` and follows '
            '`DsTextSelectionToolbarTheme`. Screen readers hear it as '
            '"Spelling suggestions" with a button per suggestion; Escape or '
            'a tap outside closes it.',
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one field with `style`, or every field in a subtree with '
            '`DsTextFieldTheme`. Its `variants` map styles one form only: '
            '`singleLine`, `multiline` or `search`. State styles (`focused`, '
            '`hovered`, `error`, `readOnly`, `disabled`) nest like CSS '
            'blocks. The touch toolbar has its own `DsTextSelectionToolbarTheme` '
            'and the loupe its own `DsTextMagnifierTheme` (size, '
            'magnification, lift, corners and shadows).',
          ),
          Example(
            snippet: 'text-field-custom',
            child: _Narrow(
              // #region text-field-custom
              child: DsTextFieldTheme(
                data: DsTextFieldThemeData(
                  variants: {
                    DsTextFieldVariant.multiline: DsTextFieldStyle(
                      textStyle: DsTheme.of(context).typography
                          .mono(DsTheme.of(context).typography.small),
                    ),
                  },
                ),
                child: Column(
                  spacing: 16,
                  children: [
                    DsTextField(
                      semanticLabel: 'Team name',
                      initialValue: 'Platform',
                      style: DsTextFieldStyle(
                        borderRadius: BorderRadius.circular(999),
                        focused: const DsTextFieldStyle(
                          borderColor: Color(0xFF0B6E4F),
                        ),
                      ),
                    ),
                    DsTextField.multiline(
                      semanticLabel: 'Commit message',
                      initialValue: 'fix(auth): refresh the session token',
                      minLines: 2,
                    ),
                  ],
                ),
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
            (
              'Tab / Shift+Tab',
              'Moves to the next or previous field. The clear button is '
                  'skipped; the show password button is a stop.',
            ),
            (
              'Enter',
              'Calls `onSubmitted`. In a multi-line field, adds a line.',
            ),
            (
              'Shift+F10 / Menu key',
              'Opens the edit menu in desktop apps (on the web, only after '
                  '`BrowserContextMenu.disableContextMenu()`).',
            ),
            (
              'Ctrl+A / ⌘A',
              'Selects all. Copy, cut, paste, undo and moving by word or '
                  'line follow the platform too.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a text field named by the `DsField` label, or by '
                '`semanticLabel` when it stands alone. The placeholder is '
                'read as a hint.',
            'Focus always shows, also after a click or tap: the edge turns '
                '2px in the focus color, drawn inside so nothing moves.',
            'The clear and show password buttons are separate buttons, '
                'named "Clear" and "Show password" or "Hide password".',
            'With a counter, the count is read with the field. In the last '
                'tenth before the limit, a polite announcement says how many '
                'characters are left.',
            'Selected text keeps at least 4.5:1 contrast on the selection '
                'fill. Read-only text keeps full contrast.',
            'The caret blinks as the platform does and stays still when '
                'reduce motion is on.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'controller',
              'TextEditingController?',
              'Holds the text and selection; one is created when null.',
            ),
            (
              'initialValue',
              'String?',
              'The starting text when there is no `controller`.',
            ),
            ('onChanged', 'ValueChanged<String>?', 'Called on every edit.'),
            (
              'onSubmitted',
              'ValueChanged<String>?',
              'Called on Enter or the keyboard\'s action key.',
            ),
            ('placeholder', 'String?', 'Shown while the field is empty.'),
            (
              'leading / trailing',
              'Widget?',
              'An icon, or a short text that sits beside the value.',
            ),
            ('clearable', 'bool', 'Adds a clear button while there is text.'),
            ('obscureText', 'bool', 'Hides the text behind bullets.'),
            (
              'revealable',
              'bool',
              'Adds a show password button to an `obscureText` field.',
            ),
            ('maxLength', 'int?', 'Shows a counter and limits the length.'),
            (
              'maxLengthEnforcement',
              'MaxLengthEnforcement?',
              '`none` makes `maxLength` a soft limit.',
            ),
            (
              'keyboardType',
              'TextInputType?',
              'The on-screen keyboard to show.',
            ),
            (
              'autofillHints',
              'Iterable<String>?',
              'What the field holds, for the platform\'s autofill.',
            ),
            (
              'spellCheck',
              'bool?',
              'Underlines misspelled words and offers replacements; null is '
                  'on for prose on iOS and Android.',
            ),
            (
              'inputFormatters',
              'List<TextInputFormatter>?',
              'Run on each change, before `maxLength`.',
            ),
            (
              'enabled',
              'bool',
              'False dims the field and skips it in Tab order.',
            ),
            ('readOnly', 'bool', 'Fixed text that can still be copied.'),
            ('error', 'bool', 'The error look, for a field outside `DsField`.'),
            (
              'semanticLabel',
              'String?',
              'Names the field when no `DsField` label does.',
            ),
            (
              'minLines / maxLines',
              'int?',
              'Multi-line only: 3 and 8 by default; null `maxLines` grows '
                  'without limit.',
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

class _CounterDemo extends StatefulWidget {
  const _CounterDemo();

  @override
  State<_CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<_CounterDemo> {
  String _summary =
      'Moves the billing page to the new layout and adds an invoice export';

  @override
  Widget build(BuildContext context) {
    return _Narrow(
      child: Column(
        spacing: 16,
        children: [
          // #region text-field-counter
          DsField(
            label: const Text('Status'),
            child: DsTextField(
              initialValue: 'Out until Monday, back for planning',
              maxLength: 40,
            ),
          ),
          DsField(
            label: const Text('Summary'),
            errorText: _summary.characters.length > 60
                ? DsLocalizations.of(context)
                      .charactersOver(_summary.characters.length - 60)
                : null,
            child: DsTextField.multiline(
              initialValue: _summary,
              minLines: 2,
              maxLength: 60,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              onChanged: (v) => setState(() => _summary = v),
            ),
          ),
          // #endregion
        ],
      ),
    );
  }
}

class _ErrorDemo extends StatefulWidget {
  const _ErrorDemo();

  @override
  State<_ErrorDemo> createState() => _ErrorDemoState();
}

class _ErrorDemoState extends State<_ErrorDemo> {
  String _email = 'ada@northwind';

  @override
  Widget build(BuildContext context) => _Narrow(
    // #region text-field-error
    child: DsField(
      label: const Text('Work email'),
      // Null for an empty or valid address, else the message.
      errorText: DsValidators.email(context)(_email),
      child: DsTextField(
        initialValue: _email,
        keyboardType: TextInputType.emailAddress,
        onChanged: (v) => setState(() => _email = v),
      ),
    ),
    // #endregion
  );
}
