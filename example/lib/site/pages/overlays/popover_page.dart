import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Popovers, and the behavior every layer shares.
class PopoverPage extends StatelessWidget {
  const PopoverPage({super.key});

  @override
  Widget build(BuildContext context) => const DocPage(
    eyebrow: 'Overlays',
    title: 'Popover',
    lead:
        'A floating panel attached to its trigger, for content richer than '
        'a menu: a short form, a quick filter, sharing options. It is not '
        'modal. The page stays usable, and Tab moves on past it.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'popover-overview',
            minHeight: 200,
            child: _InviteDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Placement',
        children: [
          DocText(
            '`side` picks the preferred side of the trigger (`bottom` by '
            'default) and `align` how the popover lines up along it. Both '
            'are preferences: near a window edge, the popover flips to the '
            'other side and shifts to stay in view.',
          ),
          Example(snippet: 'popover-placement', child: _PlacementDemo()),
        ],
      ),
      DocSection(
        title: 'Opening from elsewhere',
        children: [
          DocText(
            '`builder` gets a `DsOverlayController` made by the popover. To '
            'open or close it from other code, such as a shortcut or the '
            'popover\'s own submit button, create the controller yourself, '
            'pass it as `controller` and dispose of it with the state. The '
            'overview above does this to close after "Send invite".',
          ),
        ],
      ),
      DocSection(
        title: 'Layer behavior',
        children: [
          DocText(
            'Popovers, menus, tooltips, selects, dialogs, panels and toasts '
            'share these rules.',
          ),
          DocList([
            '**Placement.** Layers hung from a trigger (popovers, menus, '
                'tooltips, selects) flip to the other side when the '
                'preferred one is too small, shift to stay inside the '
                'window, follow the trigger while the page scrolls, and keep '
                'clear of the on-screen keyboard.',
            '**Escape** closes the innermost layer only. A tooltip takes the '
                'Escape that hides it, so the dialog behind stays open.',
            '**Outside taps** close popovers and menus without swallowing '
                'the tap: the button you tapped still works. A layer opened '
                'from inside another keeps the outer one open. Dialogs and '
                'panels close on a tap on the dimmed page.',
            '**Focus** moves into popovers, menus, dialogs and panels when '
                'they open (popovers, dialogs and panels: to the control with '
                '`autofocus`, else the first one), and back to the trigger '
                'when they close, also after a mouse click. Dialogs and '
                'panels keep Tab inside; '
                'popovers let it move on, and menus close on it. Tooltips '
                'and toasts never take focus by themselves.',
            '**System back** (the Android back button or gesture) closes the '
                'innermost open layer before the page. Toasts stay.',
            '**A trigger scrolled out of the window** closes its layer and '
                'gets focus back, so no key acts on a layer nobody can see.',
            '**Dismissible.** Dialogs and panels shown with `dismissible: '
                'false` ignore Escape, the dimmed page and system back. Their '
                'own actions close them; a menu or popover open inside one '
                'still closes on back first.',
          ]),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          DocText(
            '`style` sets one popover (`DsPopoverStyle`: `width`, '
            '`maxWidth`, `padding`, `borderRadius`…), `DsPopoverTheme` a '
            'part of the app. Without a `width`, a popover sizes to its '
            'content up to 360px. Popovers are opaque by default; see '
            '[Layers and glass](/guides/glass) for a frosted one.',
          ),
          Example(snippet: 'popover-custom', child: _CustomDemo()),
        ],
      ),
      DocSection(
        title: 'Keyboard',
        children: [
          KeyboardTable([
            (
              'Enter / Space',
              'On the trigger, opens the popover and moves focus to its '
                  'first control.',
            ),
            (
              'Tab / Shift+Tab',
              'Moves through the popover\'s controls. Past the last one, '
                  'the popover closes and focus moves to the control after '
                  'the trigger. Before the first, it closes and focus goes '
                  'back to the trigger.',
            ),
            ('Escape', 'Closes the popover; focus goes back to the trigger.'),
          ]),
        ],
      ),
      DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'A `DsButton` trigger is announced as expanded or collapsed. '
                'Another kind of trigger needs '
                '`Semantics(expanded: controller.isOpen)`.',
            'The popover is named by `semanticLabel`.',
            'Focus is never trapped, as in the WAI-ARIA non-modal dialog '
                'pattern.',
          ]),
        ],
      ),
      DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'contentBuilder',
              'WidgetBuilder',
              'Builds the popover\'s content.',
            ),
            (
              'builder',
              'DsOverlayTriggerBuilder?',
              'Builds the trigger with the controller that opens the popover.',
            ),
            (
              'controller',
              'DsOverlayController?',
              'Opens and closes it from elsewhere; made when null.',
            ),
            (
              'child',
              'Widget?',
              'A trigger that does not need the controller (pass a '
                  '`controller` then).',
            ),
            ('side', 'DsSide', '`top`, `bottom` (default), `start` or `end`.'),
            ('align', 'DsAlign', '`start` (default), `center` or `end`.'),
            (
              'semanticLabel',
              'String?',
              'Names the popover for screen readers.',
            ),
            ('style', 'DsPopoverStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsOverlayController'),
          ApiTable([
            (
              'open() / close() / toggle()',
              'void',
              'Shows or hides the layer.',
            ),
            ('isOpen', 'bool', 'Whether the layer is showing.'),
          ]),
        ],
      ),
    ],
  );
}

class _InviteDemo extends StatefulWidget {
  const _InviteDemo();

  @override
  State<_InviteDemo> createState() => _InviteDemoState();
}

class _InviteDemoState extends State<_InviteDemo> {
  final _invite = DsOverlayController();
  String _role = 'viewer';

  @override
  void dispose() {
    _invite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #region popover-overview
    return DsPopover(
      controller: _invite,
      semanticLabel: 'Invite people',
      style: const DsPopoverStyle(width: 300),
      contentBuilder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const DsField(
            label: Text('Email'),
            child: DsTextField(placeholder: 'name@company.com'),
          ),
          DsField(
            label: const Text('Role'),
            child: DsSegmentedControl<String>(
              value: _role,
              onChanged: (v) => setState(() => _role = v),
              segments: const [
                DsSegment(value: 'viewer', label: Text('Viewer')),
                DsSegment(value: 'editor', label: Text('Editor')),
              ],
            ),
          ),
          DsButton(onPressed: _invite.close, child: const Text('Send invite')),
        ],
      ),
      builder: (context, controller, _) => DsButton(
        variant: .secondary,
        leading: const DsIcon(DsIcons.plus),
        onPressed: controller.toggle,
        child: const Text('Invite'),
      ),
    );
    // #endregion
  }
}

class _PlacementDemo extends StatelessWidget {
  const _PlacementDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    alignment: WrapAlignment.center,
    children: [
      // #region popover-placement
      for (final (side, label) in [
        (DsSide.top, 'Top'),
        (DsSide.bottom, 'Bottom'),
        (DsSide.start, 'Start'),
        (DsSide.end, 'End'),
      ])
        DsPopover(
          side: side,
          align: .center,
          semanticLabel: label,
          contentBuilder: (context) => Text('Prefers the ${side.name} side.'),
          builder: (context, controller, _) => DsButton(
            variant: .secondary,
            onPressed: controller.toggle,
            child: Text(label),
          ),
        ),
      // #endregion
    ],
  );
}

class _CustomDemo extends StatelessWidget {
  const _CustomDemo();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    // #region popover-custom
    return DsPopover(
      semanticLabel: 'Keyboard shortcuts',
      style: DsPopoverStyle(
        width: 260,
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
      ),
      contentBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final (action, keys) in [
            ('Search', '⌘K'),
            ('New task', '⌘N'),
            ('Delete', '⌘⌫'),
          ])
            Row(
              children: [
                Expanded(child: Text(action)),
                DsShortcut(
                  keys,
                  textStyle: t.typography.caption.copyWith(
                    color: t.colors.textSubtle,
                  ),
                ),
              ],
            ),
        ],
      ),
      builder: (context, controller, _) => DsButton(
        variant: .ghost,
        onPressed: controller.toggle,
        child: const Text('Shortcuts'),
      ),
    );
    // #endregion
  }
}
