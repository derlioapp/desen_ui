import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Toasts: brief messages after something happened.
class ToastPage extends StatelessWidget {
  const ToastPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Overlays',
    title: 'Toast',
    lead:
        'A brief message at the bottom of the screen after something '
        'happened: saved, sent, failed. It goes away by itself, and one '
        'shows at a time. A message that must stay on screen belongs in an '
        '[Alert](/components/alert).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'toast-overview', child: _SaveDemo())],
      ),
      DocSection(
        title: 'Statuses',
        children: [
          DocText(
            '`status` adds an icon whose shape tells the status, so it never '
            'depends on color alone. Leave it out for plain news. A '
            '`danger` toast interrupts screen readers; use it for failures '
            'only.',
          ),
          Example(snippet: 'toast-statuses', child: _StatusDemo()),
        ],
      ),
      DocSection(
        title: 'Actions',
        children: [
          DocText(
            'One short action, such as Undo, goes on the end side. Choosing '
            'it runs `onAction` and dismisses the toast. A toast with an '
            'action stays twice as long, and with a screen reader on it '
            'stays until dismissed, so the action can be reached.',
          ),
          Example(snippet: 'toast-action', child: _UndoDemo()),
        ],
      ),
      DocSection(
        title: 'Timing and dismissal',
        children: [
          DocList([
            'A toast shows for 6 seconds (the theme\'s `toastDuration`), '
                '12 with an action. `duration` sets another time.',
            'The timer pauses while the pointer, a finger or keyboard focus '
                'is on the toast.',
            'The close button, the action, a sideways swipe or a newer '
                'toast dismiss it. A new toast replaces the one on screen.',
            '`showDsToast` returns a `DsToastController`; call `dismiss()` '
                'to take the toast away early, for example when the upload '
                'it reports on is cancelled.',
            'Its `closed` future completes when the toast goes, with the '
                'reason: `action`, `dismissed`, `timeout` or `replaced`. An '
                'undo flow commits the change there unless the reason is '
                '`action`.',
          ]),
        ],
      ),
      DocSection(
        title: 'Previews',
        children: [
          DocText(
            '`DsToast` is the toast\'s content without the timing and '
            'placement, for previews, onboarding screens and custom hosts.',
          ),
          Example(snippet: 'toast-preview', child: _PreviewDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Put a `DsToastTheme` around the part of the app that shows '
            'toasts: a toast carries the component themes, direction and '
            'language of the place it was opened from. For a frosted toast, '
            'see [Layers and glass](/guides/glass).',
          ),
          Example(snippet: 'toast-custom', child: _ThemedDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            ('F8', 'Moves focus into the toast, to its first control.'),
            ('Tab', 'Moves between the action and the close button.'),
            ('Enter / Space', 'Presses the focused control.'),
            (
              'Page Up / Page Down, ↑ / ↓, Home / End',
              'Scroll long text from any control in the toast, unless a '
                  'text field has focus.',
            ),
            (
              'Escape',
              'With focus in the toast, dismisses it; focus returns to where '
                  'it was before F8.',
            ),
          ]),
          DocText(
            'See [Layer behavior](/components/popover) for what all layers '
            'share.',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Screen readers hear the toast as a polite live region: the '
                'status by name ("Success"), then the title and description.',
            'A `danger` toast is announced assertively where the platform '
                'supports announcements, and heard once.',
            'The toast keeps clear of the on-screen keyboard and the status '
                'bar. Long text at a large text size scrolls inside it.',
            'Swiping is never the only way to dismiss: the close button is '
                'named "Dismiss notification", localized.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('showDsToast'),
          ApiTable([
            ('context', 'BuildContext', 'Where the toast is shown from.'),
            ('title', 'String', 'What happened ("Changes saved").'),
            ('description', 'String?', 'Context in a few words.'),
            (
              'status',
              'DsStatus?',
              '`success`, `info`, `warning`, `danger` or `neutral`.',
            ),
            (
              'actionLabel',
              'String?',
              'A short action, e.g. "Undo". Comes with `onAction`.',
            ),
            ('onAction', 'VoidCallback?', 'Runs the action.'),
            ('duration', 'Duration?', 'Overrides how long it shows.'),
          ]),
          DocText(
            'Returns a `DsToastController` with `dismiss()`, `isShowing` '
            'and `closed`, a `Future<DsToastClosedReason>`.',
          ),
          DocHeading('DsToast'),
          ApiTable([
            ('title / description', 'String / String?', 'The text.'),
            ('status', 'DsStatus?', 'Adds the status icon.'),
            (
              'actionLabel / onAction',
              'String? / VoidCallback?',
              'The action button.',
            ),
            (
              'onDismiss',
              'VoidCallback?',
              'Shows a close button that runs it.',
            ),
            ('style', 'DsToastStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _SaveDemo extends StatelessWidget {
  const _SaveDemo();

  @override
  Widget build(BuildContext context) {
    // #region toast-overview
    return DsButton(
      onPressed: () => showDsToast(
        context: context,
        title: 'Changes saved',
        description: 'Northwind website · just now',
        status: .success,
      ),
      child: const Text('Save changes'),
    );
    // #endregion
  }
}

class _StatusDemo extends StatelessWidget {
  const _StatusDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      // #region toast-statuses
      for (final (label, status, title) in [
        ('Success', DsStatus.success, 'Invoice sent'),
        ('Info', DsStatus.info, 'New version available'),
        ('Warning', DsStatus.warning, 'Storage almost full'),
        ('Error', DsStatus.danger, 'Upload failed'),
      ])
        DsButton(
          variant: .secondary,
          onPressed: () =>
              showDsToast(context: context, title: title, status: status),
          child: Text(label),
        ),
      // #endregion
    ],
  );
}

class _UndoDemo extends StatefulWidget {
  const _UndoDemo();

  @override
  State<_UndoDemo> createState() => _UndoDemoState();
}

class _UndoDemoState extends State<_UndoDemo> {
  bool _archived = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: DsListSection(
      children: [
        DsListRow(
          leading: const DsIcon(DsIcons.fileText),
          title: const Text('Q3 roadmap'),
          detail: Text(_archived ? 'Archived' : 'Open'),
          // #region toast-action
          trailing: DsButton(
            variant: .ghost,
            size: .sm,
            onPressed: _archived
                ? null
                : () {
                    setState(() => _archived = true);
                    showDsToast(
                      context: context,
                      title: 'Task archived',
                      actionLabel: 'Undo',
                      onAction: () {
                        if (mounted) setState(() => _archived = false);
                      },
                    );
                  },
            child: const Text('Archive'),
          ),
          // #endregion
        ),
      ],
    ),
  );
}

class _PreviewDemo extends StatelessWidget {
  const _PreviewDemo();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        // #region toast-preview
        DsToast(
          title: 'Changes saved',
          description: 'Northwind website · just now',
          status: .success,
          onDismiss: () {},
        ),
        DsToast(
          title: '3 tasks moved to Done',
          actionLabel: 'Undo',
          onAction: () {},
          onDismiss: () {},
        ),
        // #endregion
      ],
    ),
  );
}

class _ThemedDemo extends StatelessWidget {
  const _ThemedDemo();

  @override
  Widget build(BuildContext context) {
    // #region toast-custom
    return DsToastTheme(
      data: DsToastThemeData(
        style: DsToastStyle(
          maxWidth: 340,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 8),
        ),
      ),
      child: Builder(
        builder: (context) => DsButton(
          variant: .secondary,
          onPressed: () => showDsToast(
            context: context,
            title: 'Link copied',
            status: .success,
          ),
          child: const Text('Copy link'),
        ),
      ),
    );
    // #endregion
  }
}
