import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Modal dialogs: confirmations and short custom dialogs.
class DialogPage extends StatelessWidget {
  const DialogPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Overlays',
    title: 'Dialog',
    lead:
        'A modal question or short task over a dimmed page. Use '
        '`showDsConfirm` for a yes or no answer and `showDsDialog` for '
        'anything else. For longer content or a form with many fields, use '
        'a [Panel](/components/panel).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'dialog-overview', child: _DeleteDemo())],
      ),
      DocSection(
        title: 'Confirmations',
        children: [
          DocText(
            '`showDsConfirm` returns `true` when the user confirms. The safe '
            'choice comes first and has focus, so Enter right after opening '
            'never deletes anything. Escape and a tap on the dimmed page '
            'answer `false`. Set `destructive` for actions that destroy '
            'data: the confirm button turns red and so does the icon.',
          ),
          Example(snippet: 'dialog-confirm', child: _PublishDemo()),
        ],
      ),
      DocSection(
        title: 'Custom dialogs',
        children: [
          DocText(
            '`showDsDialog` shows any widget, usually a `DsDialog` with a '
            'title, a description and actions. The description can hold a '
            'field. Close the dialog with `Navigator.of(context).pop(value)`; '
            'the `Future` completes with that value, or `null` when the user '
            'dismissed it. With `dismissible: false`, Escape, the dimmed page '
            'and system back do nothing, so the actions must close it.',
          ),
          Example(snippet: 'dialog-custom', child: _RenameDemo()),
        ],
      ),
      DocSection(
        title: 'Layout',
        children: [
          DocText(
            'A dialog is 340px wide and narrows on small windows. Its actions '
            'share the width equally, or stack at full width when one label '
            'would not fit its share (long labels, a narrow window, large '
            'text). When the window is short, the text scrolls and the '
            'actions stay in view. Here is one at rest, outside a layer.',
          ),
          Example(snippet: 'dialog-anatomy', child: _AnatomyDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass `style` to one `DsDialog`, or put a `DsDialogTheme` around '
            'the part of the app that opens dialogs. A dialog carries the '
            'component themes, text direction and language of the place it '
            'was opened from, so the theme reaches it. Dialogs are opaque by '
            'default; see [Layers and glass](/guides/glass) for a frosted '
            'one.',
          ),
          Example(snippet: 'dialog-custom-theme', child: _ThemedDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab / Shift+Tab',
              'Moves between the dialog\'s controls. Focus stays inside the '
                  'dialog while it is open.',
            ),
            ('Enter / Space', 'Presses the focused button.'),
            (
              'Page Up / Page Down, ↑ / ↓, Home / End',
              'Scroll long content from any control in the dialog, unless a '
                  'text field has focus.',
            ),
            (
              'Escape',
              'Closes the dialog (`showDsConfirm` answers `false`), unless '
                  'it is not dismissible.',
            ),
          ]),
          DocText(
            'Focus returns to the control that opened the dialog. The '
            'system back button closes it too, unless it is not '
            'dismissible. See [Layer '
            'behavior](/components/popover) for what all layers share.',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a dialog named by its title; `alert: true` (always '
                'on for `showDsConfirm`) announces an alert dialog that needs '
                'an answer.',
            'Focus starts on the control with `autofocus`, else on the '
                'first control; put the safe choice first.',
            'On Android, iOS and macOS, screen readers hear the dimmed '
                'page as "Close" when the dialog can be dismissed.',
            'At 200% text on a small phone, the actions stack and the text '
                'scrolls; nothing is cut off. The dialog stays above the '
                'on-screen keyboard.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('showDsConfirm'),
          ApiTable([
            ('context', 'BuildContext', 'Where the dialog is opened from.'),
            ('title', 'String', 'The question ("Delete project?").'),
            ('description', 'String?', 'What happens, in a sentence or two.'),
            (
              'confirmLabel',
              'String?',
              'The confirm button; defaults to "Confirm", localized.',
            ),
            (
              'cancelLabel',
              'String?',
              'The safe choice; defaults to "Cancel", localized.',
            ),
            ('destructive', 'bool', 'Red confirm button and icon disk.'),
            ('icon', 'Widget?', 'Shown in a tinted disk above the title.'),
          ]),
          DocText('Returns `Future<bool>`: `true` only when confirmed.'),
          DocHeading('showDsDialog'),
          ApiTable([
            ('context', 'BuildContext', 'Where the dialog is opened from.'),
            (
              'builder',
              'WidgetBuilder',
              'Builds the dialog, usually a `DsDialog`.',
            ),
            (
              'dismissible',
              'bool',
              'Escape, a tap on the dimmed page and system back close it. '
                  'Default `true`.',
            ),
            (
              'scrim',
              'DsScrim',
              '`dim` (default) or `clear`, which leaves the page undimmed, '
                  'e.g. while the dialog\'s choices preview on it.',
            ),
            (
              'useRootNavigator',
              'bool',
              'Opens above every nested navigator. Default `true`.',
            ),
            (
              'routeSettings',
              'RouteSettings?',
              'Names the route for navigator observers and analytics.',
            ),
          ]),
          DocText('Returns `Future<T?>`: the value passed to `pop`, or null.'),
          DocHeading('DsDialog'),
          ApiTable([
            ('title', 'Widget', 'The heading; a `Text` also names the dialog.'),
            ('description', 'Widget?', 'Text, or a field, under the title.'),
            (
              'actions',
              'List<Widget>',
              'Buttons, safe choice first, side by side or stacked.',
            ),
            ('icon', 'Widget?', 'Shown in a tinted disk.'),
            ('destructive', 'bool', 'Uses the danger tone for the disk.'),
            ('alert', 'bool', 'Announces an alert dialog.'),
            ('style', 'DsDialogStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _DeleteDemo extends StatelessWidget {
  const _DeleteDemo();

  @override
  Widget build(BuildContext context) {
    // #region dialog-overview
    return DsButton(
      variant: .dangerSoft,
      leading: const DsIcon(DsIcons.trash),
      onPressed: () async {
        final delete = await showDsConfirm(
          context: context,
          title: 'Delete project?',
          description:
              'Northwind website and its 48 tasks will be deleted. This '
              'cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
          icon: const DsIcon(DsIcons.trash),
        );
        if (delete && context.mounted) {
          showDsToast(context: context, title: 'Project deleted');
        }
      },
      child: const Text('Delete project'),
    );
    // #endregion
  }
}

class _PublishDemo extends StatefulWidget {
  const _PublishDemo();

  @override
  State<_PublishDemo> createState() => _PublishDemoState();
}

class _PublishDemoState extends State<_PublishDemo> {
  bool? _published;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        // #region dialog-confirm
        DsButton(
          onPressed: () async {
            final publish = await showDsConfirm(
              context: context,
              title: 'Publish changes?',
              description: 'Everyone with access to the help center sees them.',
              confirmLabel: 'Publish',
              cancelLabel: 'Not yet',
            );
            if (mounted) setState(() => _published = publish);
          },
          child: const Text('Publish'),
        ),
        // #endregion
        Text(switch (_published) {
          null => 'No answer yet',
          true => 'Answer: publish',
          false => 'Answer: not yet',
        }, style: t.typography.caption.copyWith(color: t.colors.textMuted)),
      ],
    );
  }
}

class _RenameDemo extends StatefulWidget {
  const _RenameDemo();

  @override
  State<_RenameDemo> createState() => _RenameDemoState();
}

class _RenameDemoState extends State<_RenameDemo> {
  String _name = 'Northwind website';

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(_name, style: t.typography.heading.copyWith(color: t.colors.text)),
        // #region dialog-custom
        DsButton(
          variant: .secondary,
          onPressed: () async {
            var name = _name;
            final rename = await showDsDialog<bool>(
              context: context,
              builder: (context) => DsDialog(
                title: const Text('Rename project'),
                description: DsTextField(
                  initialValue: name,
                  autofocus: true,
                  semanticLabel: 'Project name',
                  onChanged: (v) => name = v,
                  onSubmitted: (_) => Navigator.of(context).pop(true),
                ),
                actions: [
                  DsButton(
                    variant: .secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  DsButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Rename'),
                  ),
                ],
              ),
            );
            if (rename == true && mounted && name.trim().isNotEmpty) {
              setState(() => _name = name.trim());
            }
          },
          child: const Text('Rename…'),
        ),
        // #endregion
      ],
    );
  }
}

class _AnatomyDemo extends StatelessWidget {
  const _AnatomyDemo();

  @override
  Widget build(BuildContext context) {
    // #region dialog-anatomy
    return DsDialog(
      icon: const DsIcon(DsIcons.mail),
      title: const Text('Invite your team'),
      description: const Text(
        'Members can see every project in Northwind and comment on tasks.',
      ),
      actions: [
        DsButton(
          variant: .secondary,
          onPressed: () {},
          child: const Text('Later'),
        ),
        DsButton(onPressed: () {}, child: const Text('Send invites')),
      ],
    );
    // #endregion
  }
}

class _ThemedDemo extends StatelessWidget {
  const _ThemedDemo();

  @override
  Widget build(BuildContext context) {
    // #region dialog-custom-theme
    return DsDialogTheme(
      data: DsDialogThemeData(
        style: DsDialogStyle(
          width: 420,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(28),
        ),
      ),
      child: Builder(
        builder: (context) => DsButton(
          variant: .secondary,
          onPressed: () => showDsConfirm(
            context: context,
            title: 'Leave the workspace?',
            description:
                'You lose access to its projects until someone '
                'invites you again.',
            confirmLabel: 'Leave',
            destructive: true,
          ),
          child: const Text('Leave workspace'),
        ),
      ),
    );
    // #endregion
  }
}
