import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Side panels and bottom sheets.
class PanelPage extends StatelessWidget {
  const PanelPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Overlays',
    title: 'Panel and sheet',
    lead:
        'A modal panel for content that needs more room than a dialog: '
        'filters, details, a settings form. It slides in from the end edge '
        'on wide windows and up from the bottom on narrow ones. For a short '
        'question, use a [Dialog](/components/dialog).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [Example(snippet: 'panel-overview', child: _FiltersDemo())],
      ),
      DocSection(
        title: 'Side panel or bottom sheet',
        children: [
          DocText(
            'By default (`DsPanelPresentation.auto`) a window narrower than '
            '640px gets a bottom sheet and a wider one a side panel. Pass '
            '`presentation` to choose. A side panel is 400px wide and full '
            'height, with the footer at the bottom. A bottom sheet fits its '
            'content, up to 90% of the window height, and its body scrolls '
            'past that. With `auto`, the panel follows the window while it '
            'is open: resizing it or turning a tablet across 640px switches '
            'between the two. For content that scrolls itself, such as a '
            'long `ListView`, pass `scrollable: false` to the `DsPanel`.',
          ),
          Example(snippet: 'panel-presentation', child: _PresentationDemo()),
        ],
      ),
      DocSection(
        title: 'Closing',
        children: [
          DocText(
            'A panel closes from its close button, Escape, a tap on the '
            'dimmed page and the system back button. A bottom sheet also '
            'closes when dragged down past a third of its height or flicked '
            'down. With `dismissible: false`, the close button is hidden and '
            'Escape, the dimmed page, dragging and system back (the Android '
            'back button, the browser\'s back) do nothing, so the panel\'s '
            'own actions must close it. `showDsPanel` completes with the '
            'value passed to `pop`.',
          ),
          Example(snippet: 'panel-required', child: _RequiredDemo()),
        ],
      ),
      DocSection(
        title: 'Live preview',
        children: [
          DocText(
            '`scrim: DsScrim.clear` leaves the page at full contrast, so '
            'settings in a short bottom sheet show their effect on the page '
            'above it as they change. The page still takes no input while '
            'the panel is open, and a tap on it still closes the panel. '
            '`showDsModal` takes the same option.',
          ),
          Example(snippet: 'panel-preview', child: _PreviewDemo()),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass `style` to one `DsPanel`, or put a `DsPanelTheme` around '
            'the part of the app that opens panels: the panel carries the '
            'opener\'s component themes. `width` sets the side panel, '
            '`sheetMaxWidth` the widest bottom sheet, `closeStyle` the close '
            'button (the app\'s button theme does not reach it). For a '
            'frosted panel, see [Layers and glass](/guides/glass).',
          ),
          Example(snippet: 'panel-custom', child: _ThemedDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Tab / Shift+Tab',
              'Moves between the panel\'s controls; focus stays inside.',
            ),
            ('Enter / Space', 'Presses the focused control.'),
            (
              'Page Up / Page Down, ↑ / ↓, Home / End',
              'Scroll long content from any control in the panel, unless a '
                  'text field has focus.',
            ),
            ('Escape', 'Closes the panel, unless it is not dismissible.'),
          ]),
          DocText(
            'Focus returns to the control that opened the panel. See [Layer '
            'behavior](/components/popover) for what all layers share.',
          ),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Announced as a dialog named by its title.',
            'The close button is named "Close", localized. Dragging is never '
                'the only way to close: the button and Escape do the same.',
            'The drag handle is decoration and is hidden from screen '
                'readers.',
            'The panel keeps clear of the system bars and the on-screen '
                'keyboard.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          DocHeading('showDsPanel'),
          ApiTable([
            ('context', 'BuildContext', 'Where the panel is opened from.'),
            (
              'builder',
              'WidgetBuilder',
              'Builds the panel, usually a `DsPanel`.',
            ),
            (
              'presentation',
              'DsPanelPresentation',
              '`auto` (default), `side` or `bottom`.',
            ),
            (
              'dismissible',
              'bool',
              'Close button, Escape, scrim, drag and system back close it. '
                  'Default `true`.',
            ),
            (
              'scrim',
              'DsScrim',
              '`dim` (default) or `clear`, which leaves the page undimmed '
                  'for a live preview.',
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
          DocHeading('DsPanel'),
          ApiTable([
            ('title', 'Widget', 'The header; a `Text` also names the panel.'),
            ('child', 'Widget', 'The content; scrolls when it does not fit.'),
            (
              'scrollable',
              'bool',
              'Set to `false` for a child that scrolls itself, such as a '
                  '`ListView`: it then gets a bounded height. Default '
                  '`true`.',
            ),
            ('footer', 'Widget?', 'Actions along the bottom.'),
            (
              'showClose',
              'bool?',
              'Shows the close button; defaults to whether the panel can be '
                  'dismissed.',
            ),
            ('style', 'DsPanelStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

/// The filters of a task list, as a panel shows them.
class TaskFilters extends StatefulWidget {
  const TaskFilters({super.key});

  @override
  State<TaskFilters> createState() => _TaskFiltersState();
}

class _TaskFiltersState extends State<TaskFilters> {
  String _status = 'open';
  String? _assignee = 'me';
  bool _overdue = false;
  bool _design = true;
  bool _engineering = true;
  bool _marketing = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 20,
    children: [
      DsField(
        label: const Text('Status'),
        child: DsSegmentedControl<String>(
          value: _status,
          onChanged: (v) => setState(() => _status = v),
          segments: const [
            DsSegment(value: 'open', label: Text('Open')),
            DsSegment(value: 'done', label: Text('Done')),
            DsSegment(value: 'all', label: Text('All')),
          ],
        ),
      ),
      DsField(
        label: const Text('Assignee'),
        child: DsSelect<String>(
          value: _assignee,
          onChanged: (v) => setState(() => _assignee = v),
          options: const [
            DsSelectOption(value: 'me', label: 'Me'),
            DsSelectOption(value: 'team', label: 'Anyone on my team'),
            DsSelectOption(value: 'none', label: 'Nobody'),
          ],
        ),
      ),
      DsField(
        label: const Text('Teams'),
        group: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            DsCheckbox(
              value: _design,
              onChanged: (v) => setState(() => _design = v!),
              label: const Text('Design'),
            ),
            DsCheckbox(
              value: _engineering,
              onChanged: (v) => setState(() => _engineering = v!),
              label: const Text('Engineering'),
            ),
            DsCheckbox(
              value: _marketing,
              onChanged: (v) => setState(() => _marketing = v!),
              label: const Text('Marketing'),
            ),
          ],
        ),
      ),
      DsSwitch(
        value: _overdue,
        onChanged: (v) => setState(() => _overdue = v),
        label: const Text('Only overdue tasks'),
      ),
    ],
  );
}

class _FiltersDemo extends StatelessWidget {
  const _FiltersDemo();

  @override
  Widget build(BuildContext context) {
    // #region panel-overview
    return DsButton(
      variant: .secondary,
      leading: const DsIcon(DsIcons.slidersHorizontal),
      onPressed: () => showDsPanel<void>(
        context: context,
        builder: (context) => DsPanel(
          title: const Text('Filters'),
          footer: DsButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Show 12 tasks'),
          ),
          child: const TaskFilters(),
        ),
      ),
      child: const Text('Filters'),
    );
    // #endregion
  }
}

/// The body of the task details panel.
class TaskDetails extends StatelessWidget {
  const TaskDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final muted = t.typography.body.copyWith(color: t.colors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DsBadge(label: Text('In review'), status: DsStatus.info),
            DsBadge(label: Text('Due Friday'), status: DsStatus.warning),
          ],
        ),
        Text(
          'Check the new onboarding screens against the brand guidelines '
          'and leave comments on anything that needs a second pass.',
          style: muted,
        ),
        const DsProgressBar(value: .6),
        Text('3 of 5 screens reviewed', style: muted),
      ],
    );
  }
}

class _PresentationDemo extends StatelessWidget {
  const _PresentationDemo();

  @override
  Widget build(BuildContext context) {
    void open(DsPanelPresentation presentation) => showDsPanel<void>(
      context: context,
      presentation: presentation,
      builder: (context) =>
          const DsPanel(title: Text('Review onboarding'), child: TaskDetails()),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        DsButton(
          variant: .secondary,
          onPressed: () => open(.auto),
          child: const Text('Automatic'),
        ),
        // #region panel-presentation
        DsButton(
          variant: .secondary,
          onPressed: () => showDsPanel<void>(
            context: context,
            presentation: .side,
            builder: (context) => const DsPanel(
              title: Text('Review onboarding'),
              child: TaskDetails(),
            ),
          ),
          child: const Text('Side panel'),
        ),
        DsButton(
          variant: .secondary,
          onPressed: () => showDsPanel<void>(
            context: context,
            presentation: .bottom,
            builder: (context) => const DsPanel(
              title: Text('Review onboarding'),
              child: TaskDetails(),
            ),
          ),
          child: const Text('Bottom sheet'),
        ),
        // #endregion
      ],
    );
  }
}

class _PreviewDemo extends StatefulWidget {
  const _PreviewDemo();

  @override
  State<_PreviewDemo> createState() => _PreviewDemoState();
}

class _PreviewDemoState extends State<_PreviewDemo> {
  final _size = ValueNotifier<double>(15);

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        ValueListenableBuilder(
          valueListenable: _size,
          builder: (context, size, _) => Text(
            'The quick brown fox jumps over the lazy dog.',
            textAlign: TextAlign.center,
            style: t.typography.body.copyWith(
              fontSize: size,
              color: t.colors.text,
            ),
          ),
        ),
        // #region panel-preview
        DsButton(
          variant: .secondary,
          onPressed: () => showDsPanel<void>(
            context: context,
            presentation: .bottom,
            scrim: .clear,
            builder: (context) => DsPanel(
              title: const Text('Text size'),
              child: ValueListenableBuilder(
                valueListenable: _size,
                builder: (context, size, _) => DsSlider(
                  value: size,
                  min: 12,
                  max: 24,
                  semanticLabel: 'Text size',
                  onChanged: (v) => _size.value = v,
                ),
              ),
            ),
          ),
          child: const Text('Text size'),
        ),
        // #endregion
      ],
    );
  }
}

class _RequiredDemo extends StatefulWidget {
  const _RequiredDemo();

  @override
  State<_RequiredDemo> createState() => _RequiredDemoState();
}

class _RequiredDemoState extends State<_RequiredDemo> {
  String? _plan;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        // #region panel-required
        DsButton(
          onPressed: () async {
            final plan = await showDsPanel<String>(
              context: context,
              dismissible: false,
              builder: (context) => DsPanel(
                title: const Text('Your trial has ended'),
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    DsButton(
                      onPressed: () => Navigator.of(context).pop('Team'),
                      child: const Text('Upgrade to Team'),
                    ),
                    DsButton(
                      variant: .ghost,
                      onPressed: () => Navigator.of(context).pop('Free'),
                      child: const Text('Continue on Free'),
                    ),
                  ],
                ),
                child: const Text(
                  'Pick a plan to keep working. On Free, projects over the '
                  'limit become read-only; nothing is deleted.',
                ),
              ),
            );
            if (mounted) setState(() => _plan = plan);
          },
          child: const Text('End trial'),
        ),
        // #endregion
        Text(
          _plan == null ? 'No plan chosen yet' : 'Chosen: $_plan',
          style: t.typography.caption.copyWith(color: t.colors.textMuted),
        ),
      ],
    );
  }
}

class _ThemedDemo extends StatelessWidget {
  const _ThemedDemo();

  @override
  Widget build(BuildContext context) {
    // #region panel-custom
    return DsPanelTheme(
      data: DsPanelThemeData(
        style: DsPanelStyle(
          width: 480,
          margin: EdgeInsets.zero,
          borderRadius: BorderRadius.zero,
        ),
      ),
      child: Builder(
        builder: (context) => DsButton(
          variant: .secondary,
          onPressed: () => showDsPanel<void>(
            context: context,
            presentation: .side,
            builder: (context) => const DsPanel(
              title: Text('Review onboarding'),
              child: TaskDetails(),
            ),
          ),
          child: const Text('Edge-to-edge panel'),
        ),
      ),
    );
    // #endregion
  }
}
