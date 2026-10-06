import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Alerts read best at a paragraph's width.
Widget _measure(Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 520),
  child: child,
);

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Feedback',
    title: 'Alert',
    lead:
        'An inline message about a part of the page: a new version, a full '
        'disk, a failed sync. It stays until the situation changes. For a '
        'short confirmation that goes away on its own, use a '
        '[Toast](/components/toast).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'alert-overview',
            child: _measure(
              // #region alert-overview
              const DsAlert(
                status: .warning,
                title: Text('Storage is 90% full'),
                description: Text(
                  'Free up space or upgrade your plan to keep uploading files.',
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Statuses',
        children: [
          const DocText(
            '`info` is the default. Each status has its own tint, ink and '
            'icon, and screen readers hear the status name before the '
            'title, so the meaning never rests on color. `neutral` uses the '
            'info icon on a gray tint.',
          ),
          Example(
            snippet: 'alert-statuses',
            child: _measure(
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  // #region alert-statuses
                  DsAlert(
                    title: Text('A new version is ready'),
                    description: Text('Reload the page to see what changed.'),
                  ),
                  DsAlert(
                    status: .success,
                    title: Text('Payment received'),
                    description: Text('We emailed the invoice to you.'),
                  ),
                  DsAlert(
                    status: .warning,
                    title: Text('Your trial ends in 3 days'),
                    description: Text('Pick a plan to keep your projects.'),
                  ),
                  DsAlert(
                    status: .danger,
                    title: Text('Could not connect'),
                    description: Text('Check your network and try again.'),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Actions',
        children: [
          const DocText(
            '`action` takes one trailing control, usually a small ghost or '
            'secondary button. Keep it to one: an alert with several '
            'choices belongs in a [Dialog](/components/dialog).',
          ),
          Example(
            snippet: 'alert-actions',
            child: _measure(
              // #region alert-actions
              DsAlert(
                status: .danger,
                title: const Text('Sync failed'),
                description: const Text('3 changes are saved on this device.'),
                action: DsButton(
                  variant: .secondary,
                  size: .xs,
                  onPressed: () {},
                  child: const Text('Retry'),
                ),
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Title only and custom icons',
        children: [
          const DocText(
            'The description is optional. `icon` replaces the status icon '
            'when another one says more, such as a clock for a deadline; '
            'the status name is still announced.',
          ),
          Example(
            snippet: 'alert-icon',
            child: _measure(
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  // #region alert-icon
                  DsAlert(title: Text('Changes are saved automatically.')),
                  DsAlert(
                    status: .warning,
                    icon: DsIcon(DsIcons.clock),
                    title: Text('Submissions close at 17:00 today'),
                  ),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Announcing',
        children: [
          const DocText(
            'An alert that appears in response to something, such as a '
            'failed save, should set `announce: true`. It becomes a live '
            'region, and screen readers read it when it shows up. Leave it '
            'off for alerts that are there when the page loads.',
          ),
          Example(
            snippet: 'alert-announce',
            child: _measure(const _SaveDemo()),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one alert with `style`, or every alert below a point '
            'with `DsAlertTheme`, whose `statuses` map styles one status. '
            'Below, every alert gets square corners and a thin edge.',
          ),
          Example(
            snippet: 'alert-custom',
            child: _measure(
              Builder(
                builder: (context) {
                  // #region alert-custom
                  // Theme colors:
                  final k = DsTheme.colorsOf(context);
                  return DsAlertTheme(
                    data: DsAlertThemeData(
                      style: DsAlertStyle(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      statuses: {
                        DsStatus.info: DsAlertStyle(borderColor: k.info.text),
                      },
                    ),
                    child: const DsAlert(
                      title: Text('Maintenance on Sunday'),
                      description: Text(
                        'The app is read-only from 02:00 to 04:00.',
                      ),
                    ),
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'The status icon is named for screen readers ("Warning", '
                '"Error"), so the status is heard before the title.',
            'Title ink keeps 4.5:1 contrast on its tint in every status and '
                'both modes. The icon keeps 3:1.',
            '`announce` makes the alert a polite live region.',
            'The alert is not focusable; its `action` is reached with Tab.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            ('title', 'Widget', 'The headline, usually a short `Text`.'),
            ('description', 'Widget?', 'Supporting text, in muted ink.'),
            ('status', 'DsStatus', 'Defaults to `info`.'),
            ('icon', 'Widget?', 'Replaces the status icon.'),
            ('action', 'Widget?', 'A trailing control, such as a button.'),
            ('announce', 'bool', 'Reads the alert aloud when it appears.'),
            ('style', 'DsAlertStyle?', 'Laid over the theme and defaults.'),
          ]),
        ],
      ),
    ],
  );
}

class _SaveDemo extends StatefulWidget {
  const _SaveDemo();

  @override
  State<_SaveDemo> createState() => _SaveDemoState();
}

class _SaveDemoState extends State<_SaveDemo> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: DsButton(
          variant: .secondary,
          onPressed: () => setState(() => _failed = !_failed),
          child: Text(_failed ? 'Dismiss' : 'Save draft'),
        ),
      ),
      // #region alert-announce
      if (_failed)
        const DsAlert(
          status: .danger,
          announce: true,
          title: Text('Could not save the draft'),
          description: Text(
            'You are offline. We will retry when you reconnect.',
          ),
        ),
      // #endregion
    ],
  );
}
