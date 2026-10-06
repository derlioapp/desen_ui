import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Text links: in running text, standalone and external.
class LinkPage extends StatelessWidget {
  const LinkPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Actions',
    title: 'Link',
    lead:
        'Takes the user somewhere: another page, a help article, a site '
        'outside the app. Use a [Button](/components/button) for actions '
        'that change something, and a [Breadcrumb](/components/breadcrumb) '
        'for the trail of parent pages.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'link-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _TrialNotice(),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Links in running text',
        children: [
          const DocText(
            'Inside a sentence, write the text as a `DsParagraph` and each '
            'link as a `DsLinkSpan`, as above. The label is part of the '
            'paragraph\'s text, so a long one wraps with the sentence, as an '
            '`<a>` in a `<p>` does on the web: the first words end one line '
            'and the rest start the next. Each link keeps what a `DsLink` '
            'has: the hover style, Tab and Enter, a focus ring around each '
            'line of the label, and link semantics.',
          ),
          Example(
            snippet: 'link-inline',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Builder(
                builder: (context) {
                  final t = DsTheme.of(context);
                  return DefaultTextStyle.merge(
                    style: t.typography.body.copyWith(color: t.colors.text),
                    // #region link-inline
                    child: DsParagraph(
                      children: [
                        const TextSpan(text: 'Before you upgrade, read the '),
                        DsLinkSpan(
                          label: 'migration guide for version 2',
                          url: Uri.parse('https://example.com/migrate'),
                          onPressed: () {},
                        ),
                        const TextSpan(text: ' and back up your data.'),
                      ],
                    ),
                    // #endregion
                  );
                },
              ),
            ),
          ),
          const DocText(
            'A `DsParagraph` holds text and links only, not other widgets. '
            'For a link that leaves the app, with its arrow, put a `DsLink` '
            'with `external: true` and `inline: true` in a `WidgetSpan` '
            'aligned to the baseline. It sits on the line like a word, but '
            'wraps inside its own box, so keep its label short.',
          ),
        ],
      ),
      DocSection(
        title: 'Standalone',
        children: [
          const DocText(
            'On its own, a link is a plain widget: under a form, at the end '
            'of a card, in a footer. There its hit area grows to the minimum '
            'tap target.',
          ),
          Example(
            snippet: 'link-standalone',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  const DsField(
                    label: Text('Password'),
                    child: DsTextField(obscureText: true, revealable: true),
                  ),
                  // #region link-standalone
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: DsLink(label: 'Forgot password?', onPressed: () {}),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'External links',
        children: [
          const DocText(
            '`external: true` adds an arrow after the label, so people know '
            'the link leaves the app. Give the address as `url` too: on the '
            'web, screen readers and the browser then treat the link as a '
            'real `<a href>`.',
          ),
          Example(
            snippet: 'link-external',
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region link-external
                DsLink(
                  label: 'Flutter documentation',
                  external: true,
                  url: Uri.parse('https://docs.flutter.dev'),
                  onPressed: () {},
                ),
                DsLink(
                  label: 'Status page',
                  external: true,
                  url: Uri.parse('https://status.example.com'),
                  onPressed: () {},
                ),
                // #endregion
              ],
            ),
          ),
          const Callout(
            'Desen does not open the address itself. Open it in '
            '`onPressed`, for example with `launchUrl` from the url_launcher '
            'package.',
            title: 'Opening the address',
          ),
        ],
      ),
      DocSection(
        title: 'Long labels and disabled',
        children: [
          const DocText(
            'A label longer than the room wraps inside the link, underlined '
            'line by line, with the external arrow after the last word. A '
            '`DsLink` wraps as one block; in running text, use a '
            '`DsLinkSpan` so the label flows with the sentence. A null '
            '`onPressed` disables either.',
          ),
          Example(
            snippet: 'link-states',
            child: Wrap(
              spacing: 32,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region link-states
                SizedBox(
                  width: 200,
                  child: DsLink(
                    label: 'Read the migration guide for version 2',
                    external: true,
                    onPressed: () {},
                  ),
                ),
                const DsLink(label: 'Download invoice', onPressed: null),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one link with `style`, or every link in a part of the '
            'app with `DsLinkTheme`. A quiet footer link can drop the '
            'underline and bring it back on hover. Keep some cue besides '
            'color where links sit in running text.',
          ),
          Example(
            snippet: 'link-custom',
            child: Builder(
              builder: (context) {
                // #region link-custom
                // Muted until hovered, for a footer.
                final k = DsTheme.colorsOf(context);
                return DsLinkTheme(
                  data: DsLinkThemeData(
                    style: DsLinkStyle(
                      foreground: k.textMuted,
                      underlineWidth: 0,
                      hovered: DsLinkStyle(
                        foreground: k.text,
                        underlineWidth: 1,
                      ),
                    ),
                  ),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      DsLink(label: 'Privacy', onPressed: () {}),
                      DsLink(label: 'Terms', onPressed: () {}),
                      DsLink(label: 'Contact', onPressed: () {}),
                    ],
                  ),
                );
                // #endregion
              },
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab',
              'Moves focus to the link; a ring shows for keyboard focus only.',
            ),
            ('Enter', 'Activates the link.'),
            (
              'Space',
              'Does nothing on the link, as in browsers; on the web the page '
                  'scrolls.',
            ),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a link with its label; `semanticLabel` replaces '
                'the label when it needs more context ("Download the March '
                'invoice").',
            'With `url`, the web build exposes a real link that the browser '
                'can open in a new tab.',
            'The underline tells links apart from text without relying on '
                'color. It sits below the descenders, so "g" and "y" stay '
                'readable.',
            'The link color keeps 4.5:1 contrast on the page, on cards and on '
                'overlays such as menus and popovers, in both modes and every '
                'contrast level.',
            'A standalone link grows its hit area to the minimum tap target. '
                'A link in running text keeps the text as its hit area; WCAG '
                '2.5.8 exempts targets inside a sentence.',
            'In a `DsParagraph`, the text around the links is read as text '
                'and each link as a link, in reading order. Each enabled link '
                'is focusable, so screen readers and the keyboard reach it as '
                'they reach a `DsLink`.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('label', 'String', 'The link text.'),
            (
              'onPressed',
              'VoidCallback?',
              'Called on activation. Null disables the link.',
            ),
            (
              'url',
              'Uri?',
              'The address, for link semantics. Does not open anything '
                  'by itself.',
            ),
            ('external', 'bool', 'Adds the up-right arrow.'),
            (
              'inline',
              'bool',
              'Inside running text: the hit area is the text, so the line '
                  'keeps its height. `false` by default.',
            ),
            (
              'semanticLabel',
              'String?',
              'Replaces the label for screen readers.',
            ),
            ('style', 'DsLinkStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'DsLinkSpan API',
        children: [
          DocText(
            'A link inside a `DsParagraph`. The paragraph takes `children` '
            '(`TextSpan`s and `DsLinkSpan`s, nested at any depth), an '
            'optional `style` laid over the surrounding text style, and '
            '`textAlign`.',
          ),
          ApiTable([
            ('label', 'String', 'The link text. Must not be empty.'),
            (
              'onPressed',
              'VoidCallback?',
              'Called on activation. Null disables the link.',
            ),
            ('url', 'Uri?', 'The address, for link semantics.'),
            (
              'semanticLabel',
              'String?',
              'Replaces the label for screen readers.',
            ),
            (
              'linkStyle',
              'DsLinkStyle?',
              'Laid over the theme and defaults; the line height stays the '
                  'paragraph\'s.',
            ),
            (
              'focusNode',
              'FocusNode?',
              'Focus node; the paragraph creates one when null.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _TrialNotice extends StatelessWidget {
  const _TrialNotice();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return DefaultTextStyle.merge(
      style: t.typography.body.copyWith(color: t.colors.text, height: 1.6),
      // #region link-overview
      child: DsParagraph(
        children: [
          const TextSpan(text: 'Your trial ends in 3 days. '),
          DsLinkSpan(label: 'Choose a plan', onPressed: () {}),
          const TextSpan(text: ' to keep your projects, or '),
          DsLinkSpan(label: 'export your data', onPressed: () {}),
          const TextSpan(text: '.'),
        ],
      ),
      // #endregion
    );
  }
}
