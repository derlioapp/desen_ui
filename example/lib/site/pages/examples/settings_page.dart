import 'dart:async';
import 'dart:typed_data';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../../links.dart';
import '../../settings.dart';
import 'frame.dart';
import 'northwind.dart';

/// Examples: account and workspace settings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    wide: true,
    eyebrow: 'Examples',
    title: 'Settings',
    lead:
        'Account and workspace settings for the same team. Upload a profile '
        'photo, edit the profile and save it to see validation, or try to '
        'delete the workspace. The appearance preferences are real: they '
        'change this whole site.',
    sections: [
      DocSection(
        title: 'Preview',
        children: [
          ScreenFrame(label: 'Northwind settings', child: NorthwindSettings()),
        ],
      ),
      DocSection(
        title: 'Built with',
        children: [
          BuiltWith([
            ('Sidebar', '/components/sidebar'),
            ('Tabs', '/components/tabs'),
            ('List', '/components/list'),
            ('Switch', '/components/switch'),
            ('Segmented control', '/components/segmented-control'),
            ('Select', '/components/select'),
            ('Avatar', '/components/avatar'),
            ('File upload', '/components/file-upload'),
            ('Form fields', '/forms'),
            ('Radio', '/components/radio'),
            ('Alert', '/components/alert'),
            ('Dialog', '/components/dialog'),
            ('Toast', '/components/toast'),
          ]),
        ],
      ),
    ],
  );
}

enum _Section {
  profile('Profile', DsIcons.user),
  preferences('Preferences', DsIcons.slidersHorizontal),
  notifications('Notifications', DsIcons.bell),
  security('Security', DsIcons.eye),
  general('General', DsIcons.settings),
  members('Members', DsIcons.inbox);

  const _Section(this.label, this.icon);
  final String label;
  final DsIconData icon;
}

/// The settings screen: a side list on wide frames, tabs on narrow ones.
class NorthwindSettings extends StatefulWidget {
  const NorthwindSettings({super.key});

  @override
  State<NorthwindSettings> createState() => _NorthwindSettingsState();
}

class _NorthwindSettingsState extends State<NorthwindSettings> {
  static const _navWidth = 212.0;
  _Section _section = _Section.profile;

  /// The workspace's scheduled deletion date, if one was asked for.
  DateTime? _deletion;

  void _go(_Section s) => setState(() => _section = s);

  Widget _body() => switch (_section) {
    _Section.profile => const _ProfileSection(),
    _Section.preferences => const _PreferencesSection(),
    _Section.notifications => const _NotificationsSection(),
    _Section.security => const _SecuritySection(),
    _Section.general => _GeneralSection(
      deletion: _deletion,
      onDeletionChanged: (d) => setState(() => _deletion = d),
    ),
    _Section.members => const _MembersSection(),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth >= 720;
      final t = DsTheme.of(context);
      final links = SiteLinks.of(context);
      final back = wide
          ? DsButton(
              variant: .ghost,
              size: .sm,
              leading: const DsIcon(DsIcons.chevronLeft),
              onPressed: () => links.go('/examples/dashboard'),
              child: const Text('Back to tasks'),
            )
          : DsButton.icon(
              variant: .ghost,
              size: .sm,
              semanticLabel: 'Back to tasks',
              icon: const DsIcon(DsIcons.chevronLeft),
              onPressed: () => links.go('/examples/dashboard'),
            );
      final body = Padding(
        padding: EdgeInsets.fromLTRB(
          wide ? 32 : 16,
          wide ? 28 : 20,
          wide ? 32 : 16,
          32,
        ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: KeyedSubtree(key: ValueKey(_section), child: _body()),
          ),
        ),
      );
      if (!wide) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsPaneHeader(
              title: Text(
                'Settings',
                style: t.typography.bodyStrong.copyWith(color: t.colors.text),
              ),
              actions: [back],
            ),
            DsTabs<_Section>(
              semanticLabel: 'Settings sections',
              value: _section,
              onChanged: _go,
              tabs: [
                for (final s in _Section.values)
                  DsTab(value: s, label: Text(s.label)),
              ],
            ),
            body,
          ],
        );
      }
      DsSidebarItem item(_Section s) => DsSidebarItem(
        leading: DsIcon(s.icon),
        label: Text(s.label),
        selected: _section == s,
        onPressed: () => _go(s),
      );
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _navWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsPaneHeader(
                  title: DsBreadcrumb(
                    items: [
                      const DsBreadcrumbItem(label: 'Settings'),
                      DsBreadcrumbItem(label: _section.label),
                    ],
                  ),
                  actions: [back],
                ),
                body,
              ],
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: _navWidth,
            child: DsSidebar(
              semanticLabel: 'Settings sections',
              style: const DsSidebarStyle(width: _navWidth),
              children: [
                const DsSidebarSection(label: Text('ACCOUNT')),
                for (final s in _Section.values.take(4)) item(s),
                const DsSidebarSection(label: Text('WORKSPACE')),
                for (final s in _Section.values.skip(4)) item(s),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// A section's title and one line on what it holds.
class _Intro extends StatelessWidget {
  const _Intro(this.title, this.description);

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.typography.title.copyWith(color: t.colors.text),
          ),
        ),
        Text(
          description,
          style: t.typography.body.copyWith(color: t.colors.textMuted),
        ),
      ],
    );
  }
}

/// Two fields side by side, or stacked when narrow.
class _Pair extends StatelessWidget {
  const _Pair(this.a, this.b);

  final Widget a;
  final Widget b;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth < 420
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [a, b],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Expanded(child: a),
              Expanded(child: b),
            ],
          ),
  );
}

// Profile.

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  bool _saving = false;

  // The simulated upload.
  static const _fileName = 'maya-portrait.jpg';
  static const _fileSize = 1482240;
  Timer? _timer;
  DsFileStatus? _status;
  double _progress = 0;
  ImageProvider? _photo;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _browse() {
    _timer?.cancel();
    setState(() {
      _status = DsFileStatus.uploading;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _progress = (_progress + .045).clamp(0, 1));
      if (_progress >= 1) {
        timer.cancel();
        setState(() {
          _status = DsFileStatus.done;
          _photo = MemoryImage(_portrait(DsTheme.colorsOf(context)));
        });
      }
    });
  }

  void _removeFile() {
    _timer?.cancel();
    setState(() {
      _status = null;
      _photo = null;
    });
  }

  Future<void> _save() async {
    final form = _form.currentState!;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!form.validateAndFocus()) return;
    form.save();
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _saving = false);
    showDsToast(
      context: context,
      title: 'Profile updated',
      description: 'People in Northwind see the changes now.',
      status: DsStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final username = RegExp(r'^[a-z0-9._-]{3,24}$');
    return Form(
      key: _form,
      autovalidateMode: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          const _Intro('Profile', 'How you appear to people in Northwind.'),
          DsField(
            label: const Text('Photo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    DsAvatar(
                      size: .lg,
                      initials: kMe.initials,
                      image: _photo,
                      toneIndex: DsAvatar.toneFor(kMe.id),
                      semanticLabel: kMe.name,
                    ),
                    Expanded(
                      child: Text(
                        'A square photo works best. It shows on tasks, '
                        'comments and mentions.',
                        style: t.typography.small.copyWith(color: k.textMuted),
                      ),
                    ),
                  ],
                ),
                DsFileUpload(
                  onBrowse: _status == DsFileStatus.uploading ? null : _browse,
                  description: const Text('PNG or JPG · up to 2 MB'),
                  files: [
                    if (_status case final status?)
                      DsFileItem(
                        name: _fileName,
                        size: _fileSize,
                        status: status,
                        progress: _progress,
                        onCancel: _removeFile,
                        onRemove: _removeFile,
                      ),
                  ],
                ),
              ],
            ),
          ),
          _Pair(
            DsTextFormField(
              label: const Text('Full name'),
              required: true,
              initialValue: kMe.name,
              autofillHints: const [AutofillHints.name],
              validator: DsValidators.required(context),
            ),
            DsTextFormField(
              label: const Text('Username'),
              required: true,
              initialValue: 'maya.chen',
              leading: Text(
                '@',
                style: t.typography.body.copyWith(color: k.textSubtle),
              ),
              validator: DsValidators.all([
                DsValidators.required(context),
                (v) => username.hasMatch(v ?? '')
                    ? null
                    : 'Use 3 to 24 lowercase letters, digits, dots or dashes.',
              ]),
            ),
          ),
          DsTextFormField(
            label: const Text('Email'),
            description: const Text('Receipts and security alerts go here.'),
            required: true,
            initialValue: kMe.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: DsValidators.all([
              DsValidators.required(context),
              DsValidators.email(context),
            ]),
          ),
          DsTextFormField.multiline(
            label: const Text('Bio'),
            initialValue:
                'Product lead at Northwind. Before that, design systems at a '
                'payments startup in Berlin.',
            minLines: 2,
            maxLines: 5,
            maxLength: 160,
            validator: DsValidators.maxLength(context, 160),
          ),
          DsSelectFormField<String>(
            label: const Text('Time zone'),
            initialValue: 'Europe/Berlin',
            options: const [
              DsSelectOption(
                value: 'America/Los_Angeles',
                label: 'Pacific Time',
                detail: 'UTC−7',
              ),
              DsSelectOption(
                value: 'America/New_York',
                label: 'Eastern Time',
                detail: 'UTC−4',
              ),
              DsSelectOption(
                value: 'Europe/London',
                label: 'London',
                detail: 'UTC+1',
              ),
              DsSelectOption(
                value: 'Europe/Berlin',
                label: 'Berlin, Paris, Madrid',
                detail: 'UTC+2',
              ),
              DsSelectOption(
                value: 'Asia/Kolkata',
                label: 'Mumbai, New Delhi',
                detail: 'UTC+5:30',
              ),
              DsSelectOption(
                value: 'Asia/Tokyo',
                label: 'Tokyo',
                detail: 'UTC+9',
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              DsButton(
                loading: _saving,
                onPressed: _save,
                child: const Text('Save changes'),
              ),
              DsButton(
                variant: .ghost,
                onPressed: () => _form.currentState!.reset(),
                child: const Text('Discard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 96 px "photo" for the simulated upload: a head and shoulders on a
/// soft gradient in one of the avatar tones, encoded as a BMP.
Uint8List _portrait(DsColors k) {
  const w = 96, h = 96, size = 54 + w * h * 3;
  final (light, ink) = DsAvatar.toneColors(k, 4);
  final deep = Color.lerp(light, ink, .45)!;
  final figure = Color.lerp(light, const Color(0xFFFFFFFF), .7)!;
  final data = ByteData(size)
    ..setUint8(0, 0x42)
    ..setUint8(1, 0x4D)
    ..setUint32(2, size, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, w, Endian.little)
    ..setInt32(22, h, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, w * h * 3, Endian.little)
    ..setUint32(38, 2835, Endian.little)
    ..setUint32(42, 2835, Endian.little);
  var o = 54;
  int byte(double v) => (v * 255).round().clamp(0, 255);
  // Rows run bottom to top.
  for (var y = h - 1; y >= 0; y--) {
    for (var x = 0; x < w; x++) {
      var c = Color.lerp(light, deep, (x + y) / (w + h))!;
      final dx = x - 48.0;
      final head = dx * dx + (y - 40.0) * (y - 40.0) <= 17 * 17;
      final body =
          dx * dx / (32 * 32) + (y - 98.0) * (y - 98.0) / (34 * 34) <= 1;
      if (head || body) c = figure;
      data
        ..setUint8(o++, byte(c.b))
        ..setUint8(o++, byte(c.g))
        ..setUint8(o++, byte(c.r));
    }
  }
  return data.buffer.asUint8List();
}

// Preferences.

class _PreferencesSection extends StatefulWidget {
  const _PreferencesSection();

  @override
  State<_PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<_PreferencesSection> {
  String _language = 'en-US';
  String _week = 'mon';
  String _clock = '24';

  @override
  Widget build(BuildContext context) {
    final scope = SiteSettingsScope.of(context);
    final site = scope.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const _Intro(
          'Preferences',
          'Appearance and regional formats. The appearance rows change this '
              'whole site.',
        ),
        DsListSection(
          header: const Text('APPEARANCE'),
          children: [
            DsListRow(
              title: const Text('Theme'),
              trailing: DsSegmentedControl<DsThemeMode>(
                semanticLabel: 'Theme',
                value: site.mode,
                onChanged: (v) => scope.onChanged(site.copyWith(mode: v)),
                segments: const [
                  DsSegment(value: DsThemeMode.system, label: Text('Auto')),
                  DsSegment(
                    value: DsThemeMode.light,
                    icon: DsIcon(DsIcons.sun),
                    semanticLabel: 'Light',
                  ),
                  DsSegment(
                    value: DsThemeMode.dark,
                    icon: DsIcon(DsIcons.moon),
                    semanticLabel: 'Dark',
                  ),
                ],
              ),
            ),
            DsListRow(
              title: const Text('Density'),
              trailing: DsSegmentedControl<DsDensity>(
                semanticLabel: 'Density',
                value: site.density,
                onChanged: (v) => scope.onChanged(site.copyWith(density: v)),
                segments: const [
                  DsSegment(value: DsDensity.compact, label: Text('Compact')),
                  DsSegment(value: DsDensity.touch, label: Text('Touch')),
                ],
              ),
            ),
            DsListRow(
              title: const Text('Contrast'),
              trailing: DsSegmentedControl<DsContrast>(
                semanticLabel: 'Contrast',
                value: site.contrast,
                onChanged: (v) => scope.onChanged(site.copyWith(contrast: v)),
                segments: const [
                  DsSegment(value: DsContrast.soft, label: Text('Soft')),
                  DsSegment(
                    value: DsContrast.standard,
                    label: Text('Standard'),
                  ),
                ],
              ),
            ),
          ],
        ),
        DsListSection(
          header: const Text('REGION'),
          children: [
            DsListRow(
              title: const Text('Language'),
              trailing: SizedBox(
                width: 164,
                child: DsSelect<String>(
                  semanticLabel: 'Language',
                  value: _language,
                  onChanged: (v) => setState(() => _language = v ?? _language),
                  options: const [
                    DsSelectOption(value: 'en-US', label: 'English (US)'),
                    DsSelectOption(value: 'en-GB', label: 'English (UK)'),
                    DsSelectOption(value: 'de', label: 'Deutsch'),
                    DsSelectOption(value: 'fr', label: 'Français'),
                    DsSelectOption(value: 'es', label: 'Español'),
                    DsSelectOption(value: 'ja', label: '日本語'),
                  ],
                ),
              ),
            ),
            DsListRow(
              title: const Text('Week starts on'),
              trailing: DsSegmentedControl<String>(
                semanticLabel: 'Week starts on',
                value: _week,
                onChanged: (v) => setState(() => _week = v),
                segments: const [
                  DsSegment(value: 'mon', label: Text('Mon')),
                  DsSegment(value: 'sun', label: Text('Sun')),
                ],
              ),
            ),
            DsListRow(
              title: const Text('Time format'),
              trailing: DsSegmentedControl<String>(
                semanticLabel: 'Time format',
                value: _clock,
                onChanged: (v) => setState(() => _clock = v),
                segments: const [
                  DsSegment(value: '12', label: Text('1:30 PM')),
                  DsSegment(value: '24', label: Text('13:30')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Notifications.

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final _on = {
    'digest': true,
    'product': false,
    'mentions': true,
    'assigned': true,
    'status': false,
  };
  String _digestTime = '08:00';

  DsListRow _toggle(String key, String title, {Widget? leading}) => DsListRow(
    leading: leading,
    title: Text(title),
    trailing: DsSwitch(
      semanticLabel: title,
      value: _on[key]!,
      onChanged: (v) => setState(() => _on[key] = v),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 24,
    children: [
      const _Intro('Notifications', 'Choose what reaches you, and where.'),
      DsListSection(
        header: const Text('EMAIL'),
        children: [
          _toggle(
            'digest',
            'Daily digest',
            leading: const DsIcon(DsIcons.mail),
          ),
          DsListRow(
            leading: const DsIcon(DsIcons.clock),
            title: const Text('Send the digest at'),
            trailing: SizedBox(
              width: 112,
              child: DsSelect<String>(
                semanticLabel: 'Digest time',
                value: _digestTime,
                // Off with the digest.
                onChanged: _on['digest']!
                    ? (v) => setState(() => _digestTime = v ?? _digestTime)
                    : null,
                options: const [
                  DsSelectOption(value: '07:00', label: '07:00'),
                  DsSelectOption(value: '08:00', label: '08:00'),
                  DsSelectOption(value: '09:00', label: '09:00'),
                  DsSelectOption(value: '17:00', label: '17:00'),
                ],
              ),
            ),
          ),
          _toggle(
            'product',
            'Product news',
            leading: const DsIcon(DsIcons.globe),
          ),
        ],
      ),
      DsListSection(
        header: const Text('PUSH AND IN-APP'),
        children: [
          _toggle(
            'mentions',
            'Mentions and replies',
            leading: const DsIcon(DsIcons.bell),
          ),
          _toggle(
            'assigned',
            'Tasks assigned to me',
            leading: const DsIcon(DsIcons.user),
          ),
          _toggle(
            'status',
            'Status changes on my tasks',
            leading: const DsIcon(DsIcons.circleCheck),
          ),
        ],
      ),
    ],
  );
}

// Security.

class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  final _newPassword = TextEditingController();
  bool _saving = false;
  bool _twoFactor = true;
  final _sessions = [
    ('MacBook Pro · Berlin', 'This device'),
    ('iPhone 16 · Berlin', 'Oct 4'),
    ('Chrome on Windows · Lisbon', 'Sep 28'),
  ];

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final form = _form.currentState!;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!form.validateAndFocus()) return;
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _saving = false);
    form.reset();
    setState(() => _validate = AutovalidateMode.disabled);
    _newPassword.clear();
    showDsToast(
      context: context,
      title: 'Password updated',
      description: 'Other devices stay signed in.',
      status: DsStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 24,
    children: [
      const _Intro('Security', 'Your password, two-step sign-in and devices.'),
      DsCard(
        style: const DsCardStyle(padding: EdgeInsets.all(20)),
        child: Form(
          key: _form,
          autovalidateMode: _validate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              DsTextFormField(
                label: const Text('Current password'),
                required: true,
                obscureText: true,
                revealable: true,
                autofillHints: const [AutofillHints.password],
                validator: DsValidators.required(context),
              ),
              DsTextFormField(
                controller: _newPassword,
                label: const Text('New password'),
                description: const Text('At least 10 characters.'),
                required: true,
                obscureText: true,
                revealable: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: DsValidators.all([
                  DsValidators.required(context),
                  DsValidators.minLength(context, 10),
                ]),
              ),
              DsTextFormField(
                label: const Text('Repeat new password'),
                required: true,
                obscureText: true,
                revealable: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: DsValidators.all([
                  DsValidators.required(context),
                  (v) => v == _newPassword.text
                      ? null
                      : 'The passwords do not match.',
                ]),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DsButton(
                  loading: _saving,
                  onPressed: _update,
                  child: const Text('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
      DsListSection(
        header: const Text('TWO-STEP SIGN-IN'),
        children: [
          DsListRow(
            leading: const DsIcon(DsIcons.circleCheck),
            title: const Text('Authenticator app'),
            detail: Text(_twoFactor ? 'On' : 'Off'),
            trailing: DsSwitch(
              semanticLabel: 'Authenticator app',
              value: _twoFactor,
              onChanged: (v) async {
                if (!v) {
                  final off = await showDsConfirm(
                    context: context,
                    title: 'Turn off two-step sign-in?',
                    description:
                        'Anyone with your password could then sign in as you.',
                    confirmLabel: 'Turn off',
                    destructive: true,
                  );
                  if (!off) return;
                }
                setState(() => _twoFactor = v);
              },
            ),
          ),
        ],
      ),
      DsListSection(
        header: const Text('SIGNED-IN DEVICES'),
        children: [
          for (final (device, seen) in _sessions)
            DsListRow(
              title: Text(device),
              detail: Text(seen == 'This device' ? seen : 'Active $seen'),
              trailing: seen == 'This device'
                  ? null
                  : DsButton(
                      variant: .ghost,
                      size: .xs,
                      onPressed: () {
                        setState(() => _sessions.remove((device, seen)));
                        showDsToast(
                          context: context,
                          title: 'Signed out',
                          description: device,
                        );
                      },
                      child: const Text('Sign out'),
                    ),
            ),
        ],
      ),
    ],
  );
}

// General (workspace).

class _GeneralSection extends StatefulWidget {
  const _GeneralSection({
    required this.deletion,
    required this.onDeletionChanged,
  });

  final DateTime? deletion;
  final ValueChanged<DateTime?> onDeletionChanged;

  @override
  State<_GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<_GeneralSection> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  bool _archived = false;
  String _address = 'northwind';

  void _save() {
    final form = _form.currentState!;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!form.validateAndFocus()) return;
    showDsToast(
      context: context,
      title: 'Workspace saved',
      status: DsStatus.success,
    );
  }

  Future<void> _archive() async {
    final ok = await showDsConfirm(
      context: context,
      title: 'Archive Northwind?',
      description:
          'Members lose access and billing stops. You can restore it from '
          'this page for 30 days.',
      confirmLabel: 'Archive',
    );
    if (ok && mounted) setState(() => _archived = true);
  }

  Future<void> _delete() async {
    final ok = await showDsDialog<bool>(
      context: context,
      builder: (_) => const _DeleteWorkspaceDialog(name: 'Northwind'),
    );
    if (ok != true || !mounted) return;
    final date = kToday.add(const Duration(days: 7));
    widget.onDeletionChanged(date);
    showDsToast(
      context: context,
      title: 'Deletion scheduled',
      description: 'Northwind will be deleted on ${longDate(date)}.',
      status: DsStatus.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final slug = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const _Intro('General', 'The workspace\'s name, address and access.'),
        if (_archived)
          DsAlert(
            status: DsStatus.warning,
            title: const Text('Northwind is archived'),
            description: const Text(
              'Members cannot open it and billing is paused.',
            ),
            action: DsButton(
              variant: .secondary,
              size: .xs,
              onPressed: () => setState(() => _archived = false),
              child: const Text('Restore'),
            ),
          ),
        if (widget.deletion case final date?)
          DsAlert(
            status: DsStatus.danger,
            announce: true,
            title: Text('Northwind will be deleted on ${longDate(date)}'),
            description: const Text(
              'Every member keeps access until then. Restore it to cancel.',
            ),
            action: DsButton(
              variant: .secondary,
              size: .xs,
              onPressed: () => widget.onDeletionChanged(null),
              child: const Text('Restore'),
            ),
          ),
        Form(
          key: _form,
          autovalidateMode: _validate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              _Pair(
                DsTextFormField(
                  label: const Text('Workspace name'),
                  required: true,
                  initialValue: 'Northwind',
                  validator: DsValidators.all([
                    DsValidators.required(context),
                    DsValidators.maxLength(context, 32),
                  ]),
                ),
                DsTextFormField(
                  label: const Text('Address'),
                  required: true,
                  initialValue: 'northwind',
                  description: Text('northwind.app/$_address'),
                  onChanged: (v) => setState(() => _address = v.trim()),
                  validator: DsValidators.all([
                    DsValidators.required(context),
                    (v) => slug.hasMatch(v ?? '')
                        ? null
                        : 'Use lowercase letters and digits, with dashes '
                              'between words.',
                  ]),
                ),
              ),
              DsFormField<String>(
                label: const Text('Default view for new members'),
                initialValue: 'mine',
                builder: (field) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DsSegmentedControl<String>(
                    value: field.value!,
                    onChanged: field.didChange,
                    segments: const [
                      DsSegment(value: 'mine', label: Text('My tasks')),
                      DsSegment(value: 'all', label: Text('All tasks')),
                      DsSegment(value: 'week', label: Text('This week')),
                    ],
                  ),
                ),
              ),
              DsRadioGroupFormField<String>(
                label: const Text('Who can join'),
                initialValue: 'invite',
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    DsRadio(
                      value: 'invite',
                      label: Text('Only people I invite'),
                    ),
                    DsRadio(
                      value: 'domain',
                      label: Text('Anyone with a northwind.app email'),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DsButton(
                  onPressed: _save,
                  child: const Text('Save workspace'),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              'Danger zone',
              style: t.typography.heading.copyWith(color: k.danger.text),
            ),
            Container(
              decoration: DsBoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(t.radii.card),
                shadows: [DsShadow.innerRing(k.danger.fill)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DangerRow(
                    title: 'Archive workspace',
                    body:
                        'Hide Northwind from every member and stop billing. '
                        'You can restore it for 30 days.',
                    action: DsButton(
                      variant: .secondary,
                      size: .sm,
                      onPressed: _archived ? null : _archive,
                      child: const Text('Archive'),
                    ),
                  ),
                  Container(height: 1, color: k.border),
                  _DangerRow(
                    title: 'Delete workspace',
                    body:
                        'Delete 39 tasks, 4 projects and every member\'s '
                        'access. This cannot be undone.',
                    action: DsButton(
                      variant: .danger,
                      size: .sm,
                      onPressed: widget.deletion == null ? _delete : null,
                      child: const Text('Delete workspace'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(title, style: t.typography.bodyStrong.copyWith(color: k.text)),
        Text(body, style: t.typography.small.copyWith(color: k.textMuted)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 440
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [text, action],
              )
            : Row(
                spacing: 16,
                children: [
                  Expanded(child: text),
                  action,
                ],
              ),
      ),
    );
  }
}

/// Asks for the workspace name before deleting it.
class _DeleteWorkspaceDialog extends StatefulWidget {
  const _DeleteWorkspaceDialog({required this.name});

  final String name;

  @override
  State<_DeleteWorkspaceDialog> createState() => _DeleteWorkspaceDialogState();
}

class _DeleteWorkspaceDialogState extends State<_DeleteWorkspaceDialog> {
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final matches = _typed.trim() == widget.name;
    return DsDialog(
      alert: true,
      destructive: true,
      style: const DsDialogStyle(width: 420),
      icon: const DsIcon(DsIcons.trash),
      title: Text('Delete ${widget.name}?'),
      description: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Text(
              'This deletes 39 tasks and 4 projects for all 8 members. The '
              'workspace stays for 7 days, then it is gone for good.',
            ),
            DsField(
              label: Text('Type "${widget.name}" to confirm'),
              child: DsTextField(
                onChanged: (v) => setState(() => _typed = v),
                onSubmitted: (_) {
                  if (matches) Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        DsButton(
          variant: .secondary,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        DsButton(
          variant: .danger,
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete workspace'),
        ),
      ],
    );
  }
}

// Members.

class _Member {
  const _Member(this.person, this.role);

  final Person person;
  final String role;
}

class _MembersSection extends StatefulWidget {
  const _MembersSection();

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  final _form = GlobalKey<FormState>();

  /// Off until the first submit, then errors follow every edit.
  AutovalidateMode _validate = AutovalidateMode.disabled;
  final _email = TextEditingController();
  String _inviteRole = 'Member';
  final _members = [for (final p in kPeople) _Member(p, p.role)];
  final _invited = <(String, String)>[('ren@lumen.studio', 'Guest')];

  static const _roles = ['Admin', 'Member', 'Guest'];

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _invite() {
    final form = _form.currentState!;
    setState(() => _validate = AutovalidateMode.onUserInteraction);
    if (!form.validateAndFocus()) return;
    final email = _email.text.trim();
    setState(() => _invited.insert(0, (email, _inviteRole)));
    form.reset();
    setState(() => _validate = AutovalidateMode.disabled);
    _email.clear();
    showDsToast(
      context: context,
      title: 'Invite sent',
      description: email,
      status: DsStatus.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    final meta = t.typography.small.copyWith(color: k.textMuted);
    List<DsSelectOption<String>> roles() => [
      for (final r in _roles) DsSelectOption(value: r, label: r),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        const _Intro(
          'Members',
          'Who works in Northwind, and what they can do.',
        ),
        DsCard(
          style: const DsCardStyle(padding: EdgeInsets.all(20)),
          child: Form(
            key: _form,
            autovalidateMode: _validate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                _Pair(
                  DsTextFormField(
                    controller: _email,
                    label: const Text('Invite by email'),
                    placeholder: 'name@company.com',
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _invite(),
                    validator: DsValidators.all([
                      DsValidators.required(context),
                      DsValidators.email(context),
                      (v) =>
                          _members.any((m) => m.person.email == v?.trim()) ||
                              _invited.any((i) => i.$1 == v?.trim())
                          ? 'This person is already in the workspace.'
                          : null,
                    ]),
                  ),
                  DsSelectFormField<String>(
                    label: const Text('Role'),
                    initialValue: 'Member',
                    options: roles(),
                    onChanged: (v) => _inviteRole = v ?? 'Member',
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DsButton(
                    leading: const DsIcon(DsIcons.mail),
                    onPressed: _invite,
                    child: const Text('Send invite'),
                  ),
                ),
              ],
            ),
          ),
        ),
        DsListRowTheme(
          data: const DsListRowThemeData(style: DsListRowStyle(iconSize: 32)),
          child: DsListSection(
            header: Text('${_members.length + _invited.length} PEOPLE'),
            children: [
              for (final (i, m) in _members.indexed)
                DsListRow(
                  leading: personAvatar(m.person),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.person.name, maxLines: 1),
                      Text(
                        m.person.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta,
                      ),
                    ],
                  ),
                  trailing: m.role == 'Owner'
                      ? const DsBadge(label: Text('Owner'), dot: false)
                      : DsMenuAnchor(
                          align: DsAlign.end,
                          semanticLabel: 'Role of ${m.person.name}',
                          items: [
                            for (final r in _roles)
                              DsMenuItem(
                                label: Text(r),
                                checked: m.role == r,
                                onPressed: () => setState(
                                  () => _members[i] = _Member(m.person, r),
                                ),
                              ),
                          ],
                          builder: (context, controller, _) => DsButton(
                            variant: .ghost,
                            size: .sm,
                            style: DsButtonStyle(foreground: k.textMuted),
                            semanticLabel:
                                'Role of ${m.person.name}: ${m.role}',
                            trailing: const DsIcon(DsIcons.chevronDown),
                            onPressed: controller.toggle,
                            child: Text(m.role),
                          ),
                        ),
                ),
              for (final (email, role) in _invited)
                DsListRow(
                  leading: const DsAvatar(size: .sm),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Invited · $role', maxLines: 1, style: meta),
                    ],
                  ),
                  trailing: DsButton(
                    variant: .ghost,
                    size: .xs,
                    onPressed: () {
                      setState(() => _invited.remove((email, role)));
                      showDsToast(
                        context: context,
                        title: 'Invite revoked',
                        description: email,
                      );
                    },
                    child: const Text('Revoke'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
