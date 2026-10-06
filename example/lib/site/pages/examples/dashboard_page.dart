import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../../links.dart';
import 'frame.dart';
import 'northwind.dart';

/// Examples: a project tracker's home screen.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    wide: true,
    eyebrow: 'Examples',
    title: 'Dashboard',
    lead:
        'The task workspace of a small product team. Search, filter and '
        'sort the tasks, select rows for bulk actions, open a row\'s menu, '
        'or add a task with **New task**. In a narrow window the sidebar '
        'moves into a menu and the table becomes a list.',
    sections: [
      DocSection(
        title: 'Preview',
        children: [
          ScreenFrame(
            label: 'Northwind dashboard',
            child: NorthwindDashboard(),
          ),
        ],
      ),
      DocSection(
        title: 'Built with',
        children: [
          BuiltWith([
            ('Sidebar', '/components/sidebar'),
            ('Pane header', '/components/pane-header'),
            ('Search field', '/components/search-field'),
            ('Popover', '/components/popover'),
            ('Card', '/components/card'),
            ('Progress', '/components/progress'),
            ('Table', '/components/table'),
            ('Badge', '/components/badge'),
            ('Avatar', '/components/avatar'),
            ('Menu', '/components/menu'),
            ('Pagination', '/components/pagination'),
            ('Dialog', '/components/dialog'),
            ('Form fields', '/forms'),
            ('Toast', '/components/toast'),
          ]),
        ],
      ),
    ],
  );
}

enum _Layout { desktop, tablet, phone }

/// Filters from the filter popover; empty sets match everything.
@immutable
class _Filter {
  const _Filter({
    this.statuses = const {},
    this.priorities = const {},
    this.overdueOnly = false,
  });

  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final bool overdueOnly;

  int get count => statuses.length + priorities.length + (overdueOnly ? 1 : 0);

  bool matches(Task t) =>
      (statuses.isEmpty || statuses.contains(t.status)) &&
      (priorities.isEmpty || priorities.contains(t.priority)) &&
      (!overdueOnly || t.isOverdue);

  _Filter copyWith({
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    bool? overdueOnly,
  }) => _Filter(
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    overdueOnly: overdueOnly ?? this.overdueOnly,
  );
}

/// The Northwind workspace: sidebar, header, summary cards and the task
/// table, reflowing to a tablet and a phone layout by its own width.
class NorthwindDashboard extends StatefulWidget {
  const NorthwindDashboard({super.key});

  @override
  State<NorthwindDashboard> createState() => _NorthwindDashboardState();
}

class _NorthwindDashboardState extends State<NorthwindDashboard> {
  static const _perPage = 8;
  static const _sidebarWidth = 212.0;

  List<Task> _tasks = seedTasks();

  /// 'mine', 'all', 'week' or a project id.
  String _view = 'all';
  String _query = '';
  _Filter _filter = const _Filter();
  DsTableSort? _sort;
  Set<Object> _selected = {};
  int _page = 1;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Data.

  bool _inView(Task t, String view) => switch (view) {
    'mine' => t.assignees.contains(kMe),
    'all' => true,
    'week' =>
      t.isOpen &&
          t.due != null &&
          !t.due!.isBefore(kToday) &&
          t.due!.isBefore(kToday.add(const Duration(days: 7))),
    _ => t.project.id == view,
  };

  int _openIn(String view) =>
      _tasks.where((t) => t.isOpen && _inView(t, view)).length;

  String get _viewName => switch (_view) {
    'mine' => 'My tasks',
    'all' => 'All tasks',
    'week' => 'Due this week',
    _ => projectById(_view).name,
  };

  List<Task> get _inCurrentView => [
    for (final t in _tasks)
      if (_inView(t, _view)) t,
  ];

  List<Task> _visible(List<DsTableColumn<Task>> columns) {
    final q = _query.trim().toLowerCase();
    final rows = [
      for (final t in _inCurrentView)
        if (_filter.matches(t) &&
            (q.isEmpty ||
                t.title.toLowerCase().contains(q) ||
                t.key.toLowerCase().contains(q)))
          t,
    ];
    final s = _sort;
    if (s == null) return rows;
    final column = columns.firstWhere((c) => c.id == s.columnId);
    final sign = s.ascending ? 1 : -1;
    // Sorted across pages, as a server would; nulls stay last.
    return rows..sort((a, b) {
      final av = column.value?.call(a), bv = column.value?.call(b);
      if (av == null || bv == null) return column.compare(a, b);
      return sign * column.compare(a, b);
    });
  }

  // Changes.

  void _setView(String view) => setState(() {
    _view = view;
    _page = 1;
    _selected = {};
  });

  void _clearFilters() => setState(() {
    _filter = const _Filter();
    _query = '';
    _search.clear();
    _page = 1;
  });

  /// Applies [change] to the tasks and offers to undo it.
  void _change(
    String title,
    List<Task> Function(List<Task>) change, {
    String? description,
  }) {
    final before = _tasks;
    setState(() {
      _tasks = change(_tasks);
      final keys = {for (final t in _tasks) t.key};
      _selected = {..._selected.where(keys.contains)};
    });
    showDsToast(
      context: context,
      title: title,
      description: description,
      actionLabel: 'Undo',
      onAction: () => setState(() => _tasks = before),
    );
  }

  void _update(Task task, Task updated, String title) => _change(
    title,
    (tasks) => [for (final t in tasks) t.key == task.key ? updated : t],
    description: '${task.key} · ${task.title}',
  );

  void _delete(Set<Object> keys) => _change(
    keys.length == 1 ? 'Task deleted' : '${keys.length} tasks deleted',
    (tasks) => [
      for (final t in tasks)
        if (!keys.contains(t.key)) t,
    ],
  );

  Future<void> _confirmDelete() async {
    final n = _selected.length;
    final ok = await showDsConfirm(
      context: context,
      title: n == 1 ? 'Delete 1 task?' : 'Delete $n tasks?',
      description:
          'They leave every view and their comments go with them. You can '
          'undo this for a few seconds.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: const DsIcon(DsIcons.trash),
    );
    if (ok && mounted) _delete({..._selected});
  }

  void _markSelectedDone() {
    final keys = {..._selected};
    _change(
      keys.length == 1
          ? '1 task marked as done'
          : '${keys.length} tasks marked as done',
      (tasks) => [
        for (final t in tasks)
          keys.contains(t.key) ? t.copyWith(status: TaskStatus.done) : t,
      ],
    );
    setState(() => _selected = {});
  }

  int _nextNumber(Project p) =>
      _tasks
          .where((t) => t.project == p)
          .fold(100, (m, t) => t.number > m ? t.number : m) +
      1;

  Future<void> _newTask() async {
    final project = kProjects.where((p) => p.id == _view).firstOrNull;
    final task = await showDsDialog<Task>(
      context: context,
      builder: (_) => _NewTaskDialog(project: project, nextNumber: _nextNumber),
    );
    if (task == null || !mounted) return;
    final before = _tasks;
    setState(() {
      _tasks = [task, ..._tasks];
      // Show it: its project's view, or everything.
      if (!_inView(task, _view)) _view = 'all';
      _filter = const _Filter();
      _query = '';
      _search.clear();
      _sort = null;
      _page = 1;
    });
    showDsToast(
      context: context,
      title: 'Task created',
      description: '${task.key} · ${task.title}',
      status: DsStatus.success,
      actionLabel: 'Undo',
      onAction: () => setState(() => _tasks = before),
    );
  }

  // Building.

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final layout = c.maxWidth >= 800
          ? _Layout.desktop
          : c.maxWidth >= 560
          ? _Layout.tablet
          : _Layout.phone;
      final pane = _pane(context, layout);
      if (layout != _Layout.desktop) return pane;
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _sidebarWidth),
            child: pane,
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: _sidebarWidth,
            child: DsSidebar(
              semanticLabel: 'Northwind',
              style: const DsSidebarStyle(width: _sidebarWidth),
              header: _WorkspaceSwitcher(onInvite: _invite),
              children: _nav(context),
            ),
          ),
        ],
      );
    },
  );

  void _invite() {
    Clipboard.setData(
      const ClipboardData(text: 'https://northwind.app/join/7Hq2'),
    );
    showDsToast(
      context: context,
      title: 'Invite link copied',
      description: 'Anyone with the link can join as a member.',
    );
  }

  List<Widget> _nav(BuildContext context, {VoidCallback? onDone}) {
    Widget item(String view, Widget icon, String label) => DsSidebarItem(
      leading: icon,
      label: Text(label),
      count: switch (_openIn(view)) {
        0 => null,
        final n => n,
      },
      selected: _view == view,
      onPressed: () {
        _setView(view);
        onDone?.call();
      },
    );
    final links = SiteLinks.of(context);
    return [
      item('mine', const DsIcon(DsIcons.user), 'My tasks'),
      item('all', const DsIcon(DsIcons.list), 'All tasks'),
      item('week', const DsIcon(DsIcons.calendar), 'Due this week'),
      const DsSidebarSection(label: Text('PROJECTS')),
      for (final p in kProjects)
        item(
          p.id,
          SizedBox.square(dimension: 16, child: Center(child: ProjectDot(p))),
          p.name,
        ),
      const DsSidebarSection(label: Text('WORKSPACE')),
      DsSidebarItem(
        leading: const DsIcon(DsIcons.settings),
        label: const Text('Settings'),
        onPressed: () {
          onDone?.call();
          links.go('/examples/settings');
        },
      ),
    ];
  }

  void _openMenu(BuildContext context) => showDsPanel<void>(
    context: context,
    builder: (panel) => DsPanel(
      title: const Text('Northwind'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _nav(context, onDone: () => Navigator.of(panel).pop()),
      ),
    ),
  );

  Widget _pane(BuildContext context, _Layout layout) {
    final t = DsTheme.of(context);
    final phone = layout == _Layout.phone;
    final search = DsSearchField(
      controller: _search,
      placeholder: 'Search tasks',
      onChanged: (v) => setState(() {
        _query = v;
        _page = 1;
      }),
    );
    final header = DsPaneHeader(
      title: Row(
        spacing: 4,
        children: [
          if (layout != _Layout.desktop)
            DsButton.icon(
              variant: .ghost,
              size: .sm,
              semanticLabel: 'Open navigation',
              icon: const DsIcon(DsIcons.menu),
              onPressed: () => _openMenu(context),
            ),
          Expanded(
            child: phone
                ? Text(
                    _viewName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.typography.bodyStrong.copyWith(
                      color: t.colors.text,
                    ),
                  )
                : DsBreadcrumb(
                    items: [
                      DsBreadcrumbItem(
                        label: 'Northwind',
                        onPressed: _view == 'all'
                            ? null
                            : () => _setView('all'),
                      ),
                      DsBreadcrumbItem(label: _viewName),
                    ],
                  ),
          ),
        ],
      ),
      actions: [
        if (!phone)
          SizedBox(width: layout == _Layout.desktop ? 200 : 176, child: search),
        _FilterButton(
          filter: _filter,
          compact: phone,
          onChanged: (f) => setState(() {
            _filter = f;
            _page = 1;
          }),
        ),
        if (phone)
          DsButton.icon(
            variant: .primary,
            size: .sm,
            semanticLabel: 'New task',
            icon: const DsIcon(DsIcons.plus),
            onPressed: _newTask,
          )
        else
          DsButton(
            size: .sm,
            leading: const DsIcon(DsIcons.plus),
            onPressed: _newTask,
            child: const Text('New task'),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: EdgeInsets.all(phone ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              if (phone) search,
              _Greeting(compact: phone),
              _Summary(tasks: _inCurrentView),
              _tasksSection(context, layout),
            ],
          ),
        ),
      ],
    );
  }

  List<DsTableColumn<Task>> _columns(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final meta = t.typography.small.copyWith(color: k.textSubtle);
    return [
      DsTableColumn<Task>(
        id: 'title',
        label: 'Task',
        value: (task) => task.title,
        sortable: true,
        width: const .flex(1, 180),
        cell: (context, task) => Row(
          spacing: 8,
          children: [
            PriorityIcon(task.priority),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      DsTableColumn<Task>(
        id: 'status',
        label: 'Status',
        value: (task) => task.status.index,
        sortable: true,
        width: const .fixed(104),
        cell: (_, task) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsBadge(
            status: task.status.tone,
            label: Text(task.status.label),
          ),
        ),
      ),
      DsTableColumn<Task>(
        id: 'assignees',
        label: 'Assignees',
        text: (task) => task.assignees.map((p) => p.name).join(', '),
        width: const .fixed(76),
        cell: (_, task) => task.assignees.isEmpty
            ? Text('None', style: meta)
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: DsAvatarGroup(
                  size: .xs,
                  max: 3,
                  semanticLabel: task.assignees.map((p) => p.name).join(', '),
                  avatars: [for (final p in task.assignees) personAvatar(p)],
                ),
              ),
      ),
      DsTableColumn<Task>(
        id: 'due',
        label: 'Due',
        value: (task) => task.due,
        text: (task) => task.due == null ? 'No date' : shortDate(task.due!),
        numeric: true,
        sortable: true,
        width: const .intrinsic(min: 72),
        cell: (_, task) => Text(
          task.due == null ? 'No date' : shortDate(task.due!),
          maxLines: 1,
          style: t.typography
              .numeric(t.typography.small)
              .copyWith(
                color: task.isOverdue
                    ? k.danger.text
                    : task.due == null
                    ? k.textSubtle
                    : k.textMuted,
                fontWeight: task.isOverdue ? FontWeight.w600 : null,
              ),
        ),
      ),
    ];
  }

  List<Widget> _rowMenu(Task task) {
    final mine = task.assignees.contains(kMe);
    return [
      DsMenuItem(
        leading: const DsIcon(DsIcons.circleCheck),
        label: Text(task.isOpen ? 'Mark as done' : 'Reopen'),
        onPressed: () => _update(
          task,
          task.copyWith(
            status: task.isOpen ? TaskStatus.done : TaskStatus.todo,
          ),
          task.isOpen ? 'Marked as done' : 'Reopened',
        ),
      ),
      DsMenuItem.submenu(
        leading: const DsIcon(DsIcons.arrowUpRight),
        label: const Text('Status'),
        submenu: [
          for (final s in TaskStatus.values)
            DsMenuItem(
              label: Text(s.label),
              checked: task.status == s,
              onPressed: () => _update(
                task,
                task.copyWith(status: s),
                'Status set to ${s.label}',
              ),
            ),
        ],
      ),
      DsMenuItem.submenu(
        leading: const DsIcon(DsIcons.slidersHorizontal),
        label: const Text('Priority'),
        submenu: [
          for (final p in TaskPriority.values)
            DsMenuItem(
              label: Text(p.label),
              checked: task.priority == p,
              onPressed: () => _update(
                task,
                task.copyWith(priority: p),
                'Priority set to ${p.label}',
              ),
            ),
        ],
      ),
      DsMenuItem(
        leading: const DsIcon(DsIcons.user),
        label: Text(mine ? 'Unassign me' : 'Assign to me'),
        onPressed: () => _update(
          task,
          task.copyWith(
            assignees: mine
                ? [
                    for (final p in task.assignees)
                      if (p != kMe) p,
                  ]
                : [kMe, ...task.assignees],
          ),
          mine ? 'Unassigned' : 'Assigned to you',
        ),
      ),
      DsMenuItem(
        leading: const DsIcon(DsIcons.link),
        label: const Text('Copy link'),
        onPressed: () {
          Clipboard.setData(
            ClipboardData(text: 'https://northwind.app/t/${task.key}'),
          );
          showDsToast(
            context: context,
            title: 'Link copied',
            description: 'northwind.app/t/${task.key}',
          );
        },
      ),
      const DsMenuDivider(),
      DsMenuItem(
        leading: const DsIcon(DsIcons.trash),
        label: const Text('Delete'),
        destructive: true,
        onPressed: () => _delete({task.key}),
      ),
    ];
  }

  Widget _tasksSection(BuildContext context, _Layout layout) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final phone = layout == _Layout.phone;
    final columns = _columns(context);
    final all = _visible(columns);
    final pages = (all.length / _perPage).ceil();
    final page = pages == 0 ? 1 : _page.clamp(1, pages);
    final from = (page - 1) * _perPage;
    final rows = all.sublist(
      from.clamp(0, all.length),
      (from + _perPage).clamp(0, all.length),
    );
    final meta = t.typography.small.copyWith(color: k.textMuted);

    final Widget heading;
    if (_selected.isEmpty) {
      heading = Row(
        spacing: 8,
        children: [
          Text('Tasks', style: t.typography.heading.copyWith(color: k.text)),
          Text('${all.length}', style: t.typography.numeric(meta)),
        ],
      );
    } else {
      heading = Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${_selected.length} selected',
            style: t.typography.bodyStrong.copyWith(color: k.text),
          ),
          DsButton(
            variant: .secondary,
            size: .xs,
            leading: const DsIcon(DsIcons.check),
            onPressed: _markSelectedDone,
            child: const Text('Mark done'),
          ),
          DsButton(
            variant: .dangerSoft,
            size: .xs,
            leading: const DsIcon(DsIcons.trash),
            onPressed: _confirmDelete,
            child: const Text('Delete'),
          ),
          DsButton(
            variant: .ghost,
            size: .xs,
            onPressed: () => setState(() => _selected = {}),
            child: const Text('Clear'),
          ),
        ],
      );
    }

    final range = Text.rich(
      TextSpan(
        children: all.isEmpty
            ? const [TextSpan(text: 'No tasks')]
            : [
                const TextSpan(text: 'Showing '),
                TextSpan(
                  text: '${from + 1}–${from + rows.length}',
                  style: t.typography.numeric(meta),
                ),
                TextSpan(text: ' of ${all.length}'),
              ],
      ),
      style: meta,
    );
    final empty = DsEmptyState(
      icon: const DsIcon(DsIcons.searchX),
      title: const Text('No tasks match'),
      description: const Text('Try another search or clear the filters.'),
      actions: [
        DsButton(
          variant: .secondary,
          size: .xs,
          onPressed: _clearFilters,
          child: const Text('Clear filters'),
        ),
      ],
    );
    final pagination = DsPagination(
      page: page,
      pageCount: pages,
      onChanged: (p) => setState(() => _page = p),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: heading,
          ),
        ),
        if (phone)
          _phoneList(context, rows, empty)
        else
          DsTable<Task>(
            semanticLabel: 'Tasks',
            columns: columns,
            rows: rows,
            rowKey: (task) => task.key,
            sort: _sort,
            onSortChanged: (s) => setState(() {
              _sort = s;
              _page = 1;
            }),
            sortLocally: false,
            selected: _selected,
            onSelectionChanged: (s) => setState(() => _selected = s),
            rowMenuBuilder: (_, task) => _rowMenu(task),
            showRowMenuButton: true,
            emptyView: empty,
          ),
        if (phone)
          Column(spacing: 12, children: [pagination, range])
        else
          Row(
            children: [
              Expanded(child: range),
              pagination,
            ],
          ),
      ],
    );
  }
}

extension on _NorthwindDashboardState {
  /// The phone's task list: one row per task, its menu on a tap.
  Widget _phoneList(BuildContext context, List<Task> rows, Widget empty) {
    final t = DsTheme.of(context);
    final k = t.colors;
    if (rows.isEmpty) {
      return DsCard(
        style: const DsCardStyle(padding: EdgeInsets.zero),
        child: empty,
      );
    }
    final meta = t.typography.small.copyWith(color: k.textSubtle);
    return DsListSection(
      children: [
        for (final task in rows)
          DsMenuAnchor(
            key: ValueKey(task.key),
            align: DsAlign.end,
            semanticLabel: 'Actions for ${task.key}',
            items: _rowMenu(task),
            builder: (context, controller, _) => DsListRow(
              leading: PriorityIcon(task.priority),
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        DsBadge(
                          status: task.status.tone,
                          label: Text(task.status.label),
                        ),
                        // The due date leads, so a narrow phone cuts the
                        // task key rather than the date.
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (task.due case final due?) ...[
                                  TextSpan(
                                    text: shortDate(due),
                                    style: task.isOverdue
                                        ? TextStyle(
                                            color: k.danger.text,
                                            fontWeight: FontWeight.w600,
                                          )
                                        : null,
                                  ),
                                  const TextSpan(text: ' · '),
                                ],
                                TextSpan(text: task.key),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.typography.numeric(meta),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: task.assignees.isEmpty
                  ? null
                  : DsAvatarGroup(
                      size: .xs,
                      max: 2,
                      semanticLabel: task.assignees
                          .map((p) => p.name)
                          .join(', '),
                      avatars: [
                        for (final p in task.assignees) personAvatar(p),
                      ],
                    ),
              onPressed: controller.toggle,
            ),
          ),
      ],
    );
  }
}

/// The workspace name with a menu, at the top of the sidebar.
class _WorkspaceSwitcher extends StatelessWidget {
  const _WorkspaceSwitcher({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final links = SiteLinks.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsMenuAnchor(
        semanticLabel: 'Workspace',
        items: [
          DsMenuItem(
            leading: const DsIcon(DsIcons.settings),
            label: const Text('Workspace settings'),
            onPressed: () => links.go('/examples/settings'),
          ),
          DsMenuItem(
            leading: const DsIcon(DsIcons.link),
            label: const Text('Copy invite link'),
            onPressed: onInvite,
          ),
          const DsMenuDivider(),
          DsMenuItem(
            leading: const DsIcon(DsIcons.logOut),
            label: const Text('Sign out'),
            onPressed: () => links.go('/examples/sign-in'),
          ),
        ],
        builder: (context, controller, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsButton(
            variant: .ghost,
            size: .sm,
            style: DsButtonStyle(foreground: k.text),
            leading: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k.accent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'N',
                style: t.typography.caption.copyWith(
                  color: k.onAccent,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            trailing: const DsIcon(DsIcons.chevronsUpDown),
            onPressed: controller.toggle,
            child: const Text('Northwind'),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          'Good morning, ${kMe.firstName}',
          style: t.typography.title.copyWith(color: k.text),
        ),
        Text(
          'Monday, Oct 5 · Sprint 14 ends Oct 9',
          style: t.typography.small.copyWith(color: k.textMuted),
        ),
      ],
    );
    if (compact) return text;
    return Row(
      children: [
        Expanded(child: text),
        DsAvatarGroup(
          max: 5,
          semanticLabel: '${kPeople.length} members',
          avatars: [for (final p in kPeople) personAvatar(p)],
        ),
      ],
    );
  }
}

/// Four numbers about the tasks in view.
class _Summary extends StatelessWidget {
  const _Summary({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final open = tasks.where((t) => t.isOpen).length;
    final inProgress = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .toList();
    final inReview = tasks.where((t) => t.status == TaskStatus.inReview).length;
    final overdue = tasks.where((t) => t.isOverdue).toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
    final done = tasks.length - open;
    final share = tasks.isEmpty ? 0.0 : done / tasks.length;
    final people = {for (final t in inProgress) ...t.assignees}.length;
    final foot = t.typography.caption.copyWith(color: k.textMuted);

    Widget note(String text) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: foot);

    final cards = [
      _Stat(
        label: 'Open',
        icon: DsIcons.inbox,
        value: '$open',
        foot: note(inReview == 1 ? '1 in review' : '$inReview in review'),
      ),
      _Stat(
        label: 'In progress',
        icon: DsIcons.clock,
        value: '${inProgress.length}',
        foot: note(people == 1 ? '1 person on it' : '$people people on it'),
      ),
      _Stat(
        label: 'Overdue',
        icon: DsIcons.triangleAlert,
        value: '${overdue.length}',
        valueColor: overdue.isEmpty ? null : k.danger.text,
        foot: note(
          overdue.isEmpty
              ? 'Nothing late'
              : 'Oldest due ${shortDate(overdue.first.due!)}',
        ),
      ),
      _Stat(
        label: 'Completed',
        icon: DsIcons.circleCheck,
        value: '${(share * 100).round()}%',
        foot: Row(
          spacing: 8,
          children: [
            Expanded(
              child: DsProgressBar(
                value: share,
                semanticLabel: 'Tasks completed',
              ),
            ),
            Text('$done/${tasks.length}', style: t.typography.numeric(foot)),
          ],
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 600 ? 4 : 2;
        const gap = 12.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.icon,
    required this.value,
    required this.foot,
    this.valueColor,
  });

  final String label;
  final DsIconData icon;
  final String value;
  final Widget foot;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return DsCard(
      style: const DsCardStyle(padding: EdgeInsets.all(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.typography.small.copyWith(color: k.textMuted),
                ),
              ),
              DsIcon(icon, size: 16, color: k.textSubtle),
            ],
          ),
          Text(
            value,
            style: t.typography
                .numeric(t.typography.display)
                .copyWith(color: valueColor ?? k.text, fontSize: 26),
          ),
          SizedBox(
            height: 18,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: foot,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Filter" with the number of active filters, opening the filter popover.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filter,
    required this.onChanged,
    required this.compact,
  });

  final _Filter filter;
  final ValueChanged<_Filter> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => DsPopover(
    align: DsAlign.end,
    semanticLabel: 'Filters',
    style: const DsPopoverStyle(width: 288),
    contentBuilder: (_) => _FilterPanel(filter: filter, onChanged: onChanged),
    builder: (context, controller, _) {
      final n = filter.count;
      if (compact) {
        return DsAnchoredBadge(
          badge: n == 0 ? const SizedBox.shrink() : DsCount(n),
          child: DsButton.icon(
            variant: .secondary,
            size: .sm,
            semanticLabel: n == 0 ? 'Filter' : 'Filter, $n active',
            icon: const DsIcon(DsIcons.slidersHorizontal),
            onPressed: controller.toggle,
          ),
        );
      }
      return DsButton(
        variant: .secondary,
        size: .sm,
        leading: const DsIcon(DsIcons.slidersHorizontal),
        trailing: n == 0 ? null : DsCount(n),
        semanticLabel: n == 0 ? null : 'Filter, $n active',
        onPressed: controller.toggle,
        child: const Text('Filter'),
      );
    },
  );
}

/// The filter popover's content. Changes apply at once, as in Linear.
class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.filter, required this.onChanged});

  final _Filter filter;
  final ValueChanged<_Filter> onChanged;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late _Filter _f = widget.filter;

  void _set(_Filter f) {
    setState(() => _f = f);
    widget.onChanged(f);
  }

  Set<E> _toggle<E>(Set<E> set, E value, bool on) =>
      on ? {...set, value} : ({...set}..remove(value));

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final label = t.typography.labelStrong.copyWith(color: k.textMuted);
    final rule = Container(height: 1, color: k.border);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text('Status', style: label),
        for (final s in TaskStatus.values)
          DsCheckbox(
            value: _f.statuses.contains(s),
            label: Text(s.label),
            onChanged: (v) => _set(
              _f.copyWith(statuses: _toggle(_f.statuses, s, v ?? false)),
            ),
          ),
        rule,
        Text('Priority', style: label),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in TaskPriority.values)
              DsChip(
                leading: PriorityIcon(p),
                label: Text(p.label),
                selected: _f.priorities.contains(p),
                onChanged: (v) =>
                    _set(_f.copyWith(priorities: _toggle(_f.priorities, p, v))),
              ),
          ],
        ),
        rule,
        DsSwitch(
          value: _f.overdueOnly,
          label: const Text('Overdue only'),
          onChanged: (v) => _set(_f.copyWith(overdueOnly: v)),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: DsButton(
            variant: .ghost,
            size: .xs,
            onPressed: _f.count == 0 ? null : () => _set(const _Filter()),
            child: const Text('Reset filters'),
          ),
        ),
      ],
    );
  }
}

/// "New task": a form in a dialog; pops with the new task.
class _NewTaskDialog extends StatefulWidget {
  const _NewTaskDialog({required this.project, required this.nextNumber});

  /// The project in view, chosen up front.
  final Project? project;
  final int Function(Project) nextNumber;

  @override
  State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  String _title = '';
  Project? _project;
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _due;
  List<Person> _assignees = const [];

  void _submit() {
    final form = _form.currentState!;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!form.validateAndFocus()) return;
    form.save();
    final project = _project!;
    Navigator.of(context).pop(
      Task(
        number: widget.nextNumber(project),
        title: _title.trim(),
        project: project,
        status: _status,
        priority: _priority,
        assignees: _assignees,
        due: _due,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    Widget pair(Widget a, Widget b) => LayoutBuilder(
      builder: (context, c) => c.maxWidth < 400
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [a, b],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(child: a),
                Expanded(child: b),
              ],
            ),
    );
    return DsDialog(
      style: const DsDialogStyle(width: 520),
      title: const Text('New task'),
      description: SizedBox(
        width: double.infinity,
        child: Form(
          key: _form,
          autovalidateMode: _validate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(
                'It lands at the top of the list. Everything here can be '
                'changed later.',
                style: t.typography.body.copyWith(color: t.colors.textMuted),
              ),
              DsTextFormField(
                label: const Text('Title'),
                required: true,
                autofocus: true,
                placeholder: 'Add SAML login to the admin console',
                textInputAction: TextInputAction.next,
                validator: DsValidators.all([
                  DsValidators.required(context),
                  DsValidators.minLength(context, 4),
                ]),
                onSaved: (v) => _title = v ?? '',
              ),
              pair(
                DsSelectFormField<Project>(
                  label: const Text('Project'),
                  required: true,
                  initialValue: widget.project,
                  placeholder: 'Choose a project',
                  options: [
                    for (final p in kProjects)
                      DsSelectOption(
                        value: p,
                        label: p.name,
                        leading: ProjectDot(p),
                      ),
                  ],
                  validator: DsValidators.required(context),
                  onSaved: (v) => _project = v,
                ),
                DsSelectFormField<TaskStatus>(
                  label: const Text('Status'),
                  initialValue: TaskStatus.todo,
                  options: [
                    for (final s in TaskStatus.values)
                      DsSelectOption(value: s, label: s.label),
                  ],
                  onSaved: (v) => _status = v ?? TaskStatus.todo,
                ),
              ),
              pair(
                DsSelectFormField<TaskPriority>(
                  label: const Text('Priority'),
                  initialValue: TaskPriority.medium,
                  options: [
                    for (final p in TaskPriority.values)
                      DsSelectOption(
                        value: p,
                        label: p.label,
                        leading: PriorityIcon(p),
                      ),
                  ],
                  onSaved: (v) => _priority = v ?? TaskPriority.medium,
                ),
                DsDateFormField(
                  label: const Text('Due date'),
                  firstDate: kToday,
                  currentDate: kToday,
                  onSaved: (v) => _due = v,
                ),
              ),
              DsMultiSelectFormField<Person>(
                label: const Text('Assignees'),
                description: const Text('Up to three people.'),
                initialValue: const [kMe],
                placeholder: 'Add people',
                options: [
                  for (final p in kPeople)
                    DsSelectOption(
                      value: p,
                      label: p.name,
                      detail: p.title,
                      leading: personAvatar(p, size: .xs),
                    ),
                ],
                validator: (v) => (v?.length ?? 0) > 3
                    ? 'Choose at most three people.'
                    : null,
                onSaved: (v) => _assignees = v ?? const [],
              ),
            ],
          ),
        ),
      ),
      actions: [
        DsButton(
          variant: .secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DsButton(onPressed: _submit, child: const Text('Create task')),
      ],
    );
  }
}
