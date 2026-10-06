import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Text links: inline, standalone and external.
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
        title: 'Inline and standalone',
        children: [
          const DocText(
            'Inside running text, put the link in a `WidgetSpan` with '
            '`PlaceholderAlignment.baseline` and set `inline: true`, as '
            'above. The link then sits on the line like a word, and its hit '
            'area stays the text, so the paragraph keeps its line height. On '
            'its own, a link is a plain widget: under a form, at the end of '
            'a card, in a footer. There its hit area grows to the minimum '
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
            'line by line, with the external arrow after the last word. The '
            'link wraps as one block: it does not flow on with the paragraph '
            'around it, so keep inline labels short. A null `onPressed` '
            'disables the link.',
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
                'An `inline` link keeps the text as its hit area; WCAG 2.5.8 '
                'exempts targets inside a sentence.',
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
      child: Text.rich(
        TextSpan(
          text: 'Your trial ends in 3 days. ',
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: DsLink(
                label: 'Choose a plan',
                inline: true,
                onPressed: () {},
              ),
            ),
            const TextSpan(text: ' to keep your projects, or '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: DsLink(
                label: 'export your data',
                inline: true,
                onPressed: () {},
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      // #endregion
    );
  }
}
