import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

// The fake company behind the example screens: its people, projects and
// tasks, the same on every run.

/// "Today" in the examples, so due dates and overdue counts never drift.
final DateTime kToday = DateTime(2026, 10, 5);

/// A member of the Northwind workspace.
@immutable
class Person {
  const Person(this.id, this.name, this.email, this.role, this.title);

  final String id;
  final String name;
  final String email;
  final String role;

  /// Job title, shown under the name.
  final String title;

  String get initials {
    final parts = name.split(' ');
    return '${parts.first[0]}${parts.last[0]}';
  }

  String get firstName => name.split(' ').first;
}

const kPeople = [
  Person('maya', 'Maya Chen', 'maya@northwind.app', 'Owner', 'Product lead'),
  Person('jonas', 'Jonas Weber', 'jonas@northwind.app', 'Admin', 'Engineering'),
  Person('priya', 'Priya Raman', 'priya@northwind.app', 'Member', 'Design'),
  Person('lucas', 'Lucas Moreau', 'lucas@northwind.app', 'Member', 'Frontend'),
  Person('aisha', 'Aisha Bello', 'aisha@northwind.app', 'Member', 'Backend'),
  Person('tom', 'Tom Becker', 'tom@northwind.app', 'Member', 'Mobile'),
  Person(
    'sofia',
    'Sofia Alvarez',
    'sofia@northwind.app',
    'Member',
    'Marketing',
  ),
  Person('daniel', 'Daniel Kim', 'daniel@northwind.app', 'Guest', 'Contractor'),
];

/// The signed-in user.
const Person kMe = Person(
  'maya',
  'Maya Chen',
  'maya@northwind.app',
  'Owner',
  'Product lead',
);

Person personById(String id) => kPeople.firstWhere((p) => p.id == id);

/// A person's avatar, colored the same everywhere.
DsAvatar personAvatar(Person p, {DsSize size = DsSize.sm}) => DsAvatar(
  initials: p.initials,
  toneIndex: DsAvatar.toneFor(p.id),
  size: size,
  semanticLabel: p.name,
);

@immutable
class Project {
  const Project(this.id, this.name, this.prefix, this.tone);

  final String id;
  final String name;

  /// Prefix of the task keys, e.g. "WEB" in "WEB-112".
  final String prefix;

  /// Avatar tone used for the project's color dot.
  final int tone;
}

const kProjects = [
  Project('web', 'Website relaunch', 'WEB', 1),
  Project('app', 'Mobile app', 'APP', 3),
  Project('bil', 'Billing v2', 'BIL', 5),
  Project('plt', 'Platform', 'PLT', 6),
];

Project projectById(String id) => kProjects.firstWhere((p) => p.id == id);

enum TaskStatus {
  todo('Todo', DsStatus.neutral),
  inProgress('In progress', DsStatus.info),
  inReview('In review', DsStatus.warning),
  done('Done', DsStatus.success);

  const TaskStatus(this.label, this.tone);
  final String label;
  final DsStatus tone;
}

enum TaskPriority {
  urgent('Urgent'),
  high('High'),
  medium('Medium'),
  low('Low');

  const TaskPriority(this.label);
  final String label;
}

@immutable
class Task {
  const Task({
    required this.number,
    required this.title,
    required this.project,
    required this.status,
    required this.priority,
    required this.assignees,
    required this.due,
  });

  final int number;
  final String title;
  final Project project;
  final TaskStatus status;
  final TaskPriority priority;
  final List<Person> assignees;
  final DateTime? due;

  String get key => '${project.prefix}-$number';

  bool get isOpen => status != TaskStatus.done;

  bool get isOverdue => isOpen && due != null && due!.isBefore(kToday);

  Task copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    List<Person>? assignees,
  }) => Task(
    number: number,
    title: title,
    project: project,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assignees: assignees ?? this.assignees,
    due: due,
  );
}

const _titles = {
  'web': [
    'Migrate pricing page to the new grid',
    'Write copy for the customers page',
    'Fix hero video autoplay on Safari',
    'Add a cookie preferences center',
    'Redirect legacy blog URLs',
    'Bring home page LCP under 2 seconds',
    'Localize the marketing site into German',
    'Triage accessibility audit findings',
    'Replace stock photos on the About page',
    'Publish the changelog as an RSS feed',
    'Ship the new footer navigation',
  ],
  'app': [
    'Offline mode for task lists',
    'Notification settings screen',
    'Crash when attaching large photos',
    'Biometric sign-in on Android',
    'Home screen widget for today\'s tasks',
    'Cut cold start below 1.5 seconds',
    'Dark mode polish for onboarding',
    'Deep links into comment threads',
    'Haptics on swipe actions',
    'Upgrade to the new navigation stack',
  ],
  'bil': [
    'Prorate mid-cycle seat changes',
    'Redesign the invoice PDF',
    'Support EU VAT reverse charge',
    'Dunning emails for failed payments',
    'Usage-based pricing prototype',
    'Annual plan discount banner',
    'Retry webhooks with backoff',
    'Validate UK and AU tax IDs',
    'Move customers to new price IDs',
  ],
  'plt': [
    'Rotate staging API keys',
    'Upgrade to Postgres 17',
    'Rate limits for the public API',
    'SAML single sign-on for Enterprise',
    'Export the audit log as CSV',
    'Reduce p95 search latency',
    'Dashboard for background jobs',
    'Remove feature flags left from Q2',
    'Enforce the 90-day data retention policy',
  ],
};

/// 39 tasks across four projects: open ones by due date (overdue first),
/// then the finished ones, most recent first.
List<Task> seedTasks() {
  final tasks = <Task>[];
  var i = 0;
  for (final project in kProjects) {
    final titles = _titles[project.id]!;
    for (var n = 0; n < titles.length; n++, i++) {
      final s = (i * 7 + n) % 9;
      final status = s < 3
          ? TaskStatus.todo
          : s < 5
          ? TaskStatus.inProgress
          : s < 6
          ? TaskStatus.inReview
          : TaskStatus.done;
      final p = (i * 7 + n * 3) % 20;
      final priority = p < 2
          ? TaskPriority.urgent
          : p < 7
          ? TaskPriority.high
          : p < 15
          ? TaskPriority.medium
          : TaskPriority.low;
      final lead = kPeople[(i * 3 + 1) % kPeople.length];
      final second = kPeople[(i * 5 + 2) % kPeople.length];
      final done = status == TaskStatus.done;
      tasks.add(
        Task(
          number: 96 + n * 3 + project.tone,
          title: titles[n],
          project: project,
          status: status,
          priority: priority,
          assignees: [
            if (i % 5 == 1) kMe else lead,
            if (i % 3 == 0 && second.id != lead.id && second.id != kMe.id)
              second,
          ],
          due: done
              ? kToday.subtract(Duration(days: 1 + (i * 7) % 20))
              : i % 11 == 7
              ? null
              : kToday.add(Duration(days: (i * 13) % 34 - 4)),
        ),
      );
    }
  }
  int byDue(Task a, Task b) => a.due == null
      ? (b.due == null ? 0 : 1)
      : b.due == null
      ? -1
      : a.due!.compareTo(b.due!);
  return [
    ...tasks.where((t) => t.isOpen).toList()..sort(byDue),
    ...tasks.where((t) => !t.isOpen).toList()..sort((a, b) => byDue(b, a)),
  ];
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Oct 14".
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "Oct 14, 2026".
String longDate(DateTime d) => '${shortDate(d)}, ${d.year}';

/// A small color dot for a project, from the avatar tones.
class ProjectDot extends StatelessWidget {
  const ProjectDot(this.project, {super.key, this.size = 8});

  final Project project;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DsAvatar.toneColors(k, project.tone).$2,
        borderRadius: BorderRadius.circular(size / 3),
      ),
    );
  }
}

/// Linear-style priority mark: three bars filled to the level, or an
/// exclamation box for urgent.
class PriorityIcon extends StatelessWidget {
  const PriorityIcon(this.priority, {super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final Widget mark;
    if (priority == TaskPriority.urgent) {
      mark = Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: k.danger.fill,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '!',
          style: t.typography.caption.copyWith(
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w700,
            color: k.danger.onFill,
          ),
        ),
      );
    } else {
      final level = 3 - priority.index + 1; // high 3, medium 2, low 1
      mark = SizedBox(
        width: 14,
        height: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 1.5,
          children: [
            for (var b = 0; b < 3; b++)
              Container(
                width: 3,
                height: 6.0 + b * 3,
                margin: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: b < level ? k.textMuted : k.channelStrong,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      );
    }
    return Semantics(
      label: 'Priority: ${priority.label}',
      child: ExcludeSemantics(child: mark),
    );
  }
}
