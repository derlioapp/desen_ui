import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// The reference page: every component page follows its order (overview,
/// variants and states, customizing, keyboard, accessibility, API).
class ButtonPage extends StatelessWidget {
  const ButtonPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Actions',
    title: 'Button',
    lead:
        'Starts an action. One primary button per view for the main '
        'action; secondary for everything else; tinted for an action that '
        'should stand out without being the main one; ghost in toolbars and '
        'dense rows; danger only to confirm something destructive.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'button-overview',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region button-overview
                DsButton(onPressed: () {}, child: const Text('Save')),
                DsButton(
                  variant: .secondary,
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Variants',
        children: [
          const DocText(
            '`primary` is filled with the accent; `secondary` is a raised '
            'neutral control; `tinted` puts accent text on a light wash of '
            'the accent; `ghost` has no fill until hovered; '
            '`dangerSoft` is a quiet destructive action for lists and '
            'toolbars; `danger` confirms a destructive action in a dialog; '
            '`neutral` is filled with the ink instead of the accent; '
            '`inverse` stands on an accent ground.',
          ),
          Example(
            snippet: 'button-variants',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region button-variants
                DsButton(onPressed: () {}, child: const Text('Primary')),
                DsButton(
                  variant: .secondary,
                  onPressed: () {},
                  child: const Text('Secondary'),
                ),
                DsButton(
                  variant: .tinted,
                  onPressed: () {},
                  child: const Text('Tinted'),
                ),
                DsButton(
                  variant: .ghost,
                  onPressed: () {},
                  child: const Text('Ghost'),
                ),
                DsButton(
                  variant: .dangerSoft,
                  onPressed: () {},
                  child: const Text('Remove'),
                ),
                DsButton(
                  variant: .danger,
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
                DsButton(
                  variant: .neutral,
                  onPressed: () {},
                  child: const Text('Neutral'),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Neutral and inverse',
        children: [
          const DocText(
            '`neutral` has the weight of `primary` without the brand color: '
            'near-black with a white label in light mode, soft white with a '
            'dark label in dark mode, like the dark default button of iOS '
            'and Vercel. Use it where the accent is kept for links, marks '
            'and selection. `inverse` is the primary button turned inside '
            'out for an accent ground, such as a hero band or an accent '
            'card, where `primary` would vanish: the accent\'s label color '
            'as the fill, the accent as the label, and a focus ring that '
            'shows on the accent. Hover and press keep both labels at 4.5:1 '
            'or more for every brand color.',
          ),
          Example(
            snippet: 'button-neutral-inverse',
            child: Builder(
              builder: (context) {
                final k = DsTheme.colorsOf(context);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // #region button-neutral-inverse
                    DsButton(
                      variant: .neutral,
                      leading: const DsIcon(DsIcons.plus),
                      onPressed: () {},
                      child: const Text('New project'),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: k.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          Flexible(
                            child: Text(
                              'Try Pro free for 14 days',
                              style: TextStyle(color: k.onAccent),
                            ),
                          ),
                          DsButton(
                            variant: .inverse,
                            onPressed: () {},
                            child: const Text('Start trial'),
                          ),
                        ],
                      ),
                    ),
                    // #endregion
                  ],
                );
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Tinted',
        children: [
          const DocText(
            'The typical iOS button: accent text on a light wash of the '
            'accent, with no edge or shadow. It draws the eye less than '
            '`primary` and more than `secondary`, so it suits an action '
            'that matters but is not the main one ("Add to calendar" under '
            'an event), or a row of equal actions. The wash is about 15% of '
            'the accent in light mode and a little more in dark mode; hover '
            'and press deepen it. The text stays at 4.5:1 or more on every '
            'layer.',
          ),
          Example(
            snippet: 'button-tinted',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region button-tinted
                DsButton(
                  variant: .tinted,
                  leading: const DsIcon(DsIcons.calendar),
                  onPressed: () {},
                  child: const Text('Add to calendar'),
                ),
                DsButton(
                  variant: .tinted,
                  size: .sm,
                  onPressed: () {},
                  child: const Text('Follow'),
                ),
                DsButton.icon(
                  variant: .tinted,
                  icon: const DsIcon(DsIcons.share),
                  semanticLabel: 'Share',
                  onPressed: () {},
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Sizes',
        children: [
          const DocText(
            'Four sizes; `md` is the default. Heights follow the theme\'s '
            'density, and on phones every button gets a 44px tap area while '
            'it keeps its drawn size.',
          ),
          Example(
            snippet: 'button-sizes',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region button-sizes
                DsButton(
                  size: .xs,
                  onPressed: () {},
                  child: const Text('Extra small'),
                ),
                DsButton(
                  size: .sm,
                  onPressed: () {},
                  child: const Text('Small'),
                ),
                DsButton(
                  size: .md,
                  onPressed: () {},
                  child: const Text('Medium'),
                ),
                DsButton(
                  size: .lg,
                  onPressed: () {},
                  child: const Text('Large'),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Icons',
        children: [
          const DocText(
            'Icons go before or after the label. An icon-only button needs '
            'a `semanticLabel`, which also names it for screen readers; '
            'pair it with a tooltip.',
          ),
          Example(
            snippet: 'button-icons',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // #region button-icons
                DsButton(
                  variant: .secondary,
                  leading: const DsIcon(DsIcons.plus),
                  onPressed: () {},
                  child: const Text('New task'),
                ),
                DsButton(
                  variant: .ghost,
                  trailing: const DsIcon(DsIcons.chevronDown),
                  onPressed: () {},
                  child: const Text('Sort'),
                ),
                DsTooltip(
                  message: 'More',
                  child: DsButton.icon(
                    variant: .ghost,
                    icon: const DsIcon(DsIcons.ellipsis),
                    semanticLabel: 'More',
                    onPressed: () {},
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Loading and disabled',
        children: [
          const DocText(
            'While `loading`, presses are ignored but the button keeps its '
            'focus and size, and screen readers hear "loading". A null '
            '`onPressed` disables the button.',
          ),
          Example(snippet: 'button-states', child: const _LoadingDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one button with `style`, a part of the app with '
            '`DsButtonTheme`, or the whole app through `DsComponentThemes`. '
            'State styles (`hovered`, `pressed`, `disabled`…) nest like CSS '
            'blocks. See [Theming](/theming) for app-wide tokens.',
          ),
          Example(
            snippet: 'button-custom',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region button-custom
                DsButton(
                  variant: .secondary,
                  style: DsButtonStyle(
                    borderRadius: BorderRadius.circular(999),
                    hovered: const DsButtonStyle(foreground: Color(0xFF0B6E4F)),
                  ),
                  onPressed: () {},
                  child: const Text('Rounded'),
                ),
                DsButtonTheme(
                  data: const DsButtonThemeData(size: .sm, variant: .ghost),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DsButton(onPressed: () {}, child: const Text('Small')),
                      DsButton(onPressed: () {}, child: const Text('Ghost')),
                    ],
                  ),
                ),
                // #endregion
              ],
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
              'Moves focus to the button; a ring shows for keyboard focus only.',
            ),
            ('Enter / Space', 'Presses the button.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a button with its label; icon-only buttons are '
                'named by `semanticLabel`.',
            'Disabled and loading states are announced.',
            'Labels keep 4.5:1 contrast on their fill in every tone, both '
                'modes and every contrast level.',
            'Tap area: 24px on desktop, 44px on iOS and Android.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'onPressed',
              'VoidCallback?',
              'Called on press. Null disables the button.',
            ),
            ('child', 'Widget', 'The label, usually a `Text`.'),
            (
              'variant',
              'DsButtonVariant?',
              'Defaults to the theme\'s, then `primary`.',
            ),
            ('size', 'DsSize?', '`xs`, `sm`, `md` (default) or `lg`.'),
            ('leading / trailing', 'Widget?', 'Icons around the label.'),
            ('loading', 'bool', 'Shows a spinner and ignores presses.'),
            (
              'semanticExpanded',
              'bool?',
              'Announced as expanded or collapsed (for menu triggers).',
            ),
            ('style', 'DsButtonStyle?', 'Laid over the theme and defaults.'),
            (
              'semanticLabel',
              'String?',
              'Names the button; required for `DsButton.icon`.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _LoadingDemo extends StatefulWidget {
  const _LoadingDemo();

  @override
  State<_LoadingDemo> createState() => _LoadingDemoState();
}

class _LoadingDemoState extends State<_LoadingDemo> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      // #region button-states
      DsButton(loading: _saving, onPressed: _save, child: const Text('Save')),
      const DsButton(onPressed: null, child: Text('Disabled')),
      // #endregion
    ],
  );
}
