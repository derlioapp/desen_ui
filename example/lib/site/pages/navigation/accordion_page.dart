import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class AccordionPage extends StatelessWidget {
  const AccordionPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Navigation',
    title: 'Accordion',
    lead:
        'Stacks sections that open and close in place, so a long page shows '
        'only what the reader asks for: FAQs, settings groups, order '
        'details. When people need to compare sections side by side, show '
        'them all or use [Tabs](/components/tabs).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          const DocText(
            'By default one section is open at a time: opening a section '
            'closes the others. The accordion keeps its own state, starting '
            'from `initialValue`; each section is identified by its `value`.',
          ),
          Example(
            snippet: 'accordion-overview',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              // #region accordion-overview
              child: const DsAccordion<String>(
                initialValue: {'delete'},
                items: [
                  DsAccordionItem(
                    value: 'delete',
                    title: Text('How do I delete my account?'),
                    child: Text(
                      'Go to Settings, then Security, and choose Delete '
                      'account. You can undo it within 30 days.',
                    ),
                  ),
                  DsAccordionItem(
                    value: 'invoice',
                    title: Text('Where can I download invoices?'),
                    child: Text(
                      'The Billing tab lists every invoice with a PDF link.',
                    ),
                  ),
                  DsAccordionItem(
                    value: 'seats',
                    title: Text('How many people can I add?'),
                    child: Text(
                      'The Team plan has no member limit. Guests are counted '
                      'separately.',
                    ),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Several open',
        children: [
          const DocText(
            'With `allowMultiple`, each section opens and closes on its own.',
          ),
          Example(
            snippet: 'accordion-multiple',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              // #region accordion-multiple
              child: const DsAccordion<String>(
                allowMultiple: true,
                initialValue: {'shipping', 'payment'},
                items: [
                  DsAccordionItem(
                    value: 'shipping',
                    title: Text('Shipping address'),
                    child: Text('Ada Lovelace, 12 Analytical Row, London'),
                  ),
                  DsAccordionItem(
                    value: 'payment',
                    title: Text('Payment'),
                    child: Text('Visa ending in 4242, billed on delivery'),
                  ),
                  DsAccordionItem(
                    value: 'gift',
                    title: Text('Gift message'),
                    child: Text('No message added.'),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Controlled',
        children: [
          DocText(
            'Pass `value` and `onChanged` to hold the open sections yourself, '
            'for example to open or close them all from a button. A '
            'controlled accordion without `onChanged` cannot change, so its '
            'headers are disabled.',
          ),
          Example(snippet: 'accordion-controlled', child: _ControlledDemo()),
        ],
      ),
      DocSection(
        title: 'Disabled sections',
        children: [
          const DocText(
            '`enabled: false` keeps a section\'s header from opening or '
            'closing it. The header is muted and skipped by Tab.',
          ),
          Example(
            snippet: 'accordion-disabled',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              // #region accordion-disabled
              child: const DsAccordion<String>(
                items: [
                  DsAccordionItem(
                    value: 'general',
                    title: Text('General'),
                    child: Text('Name, description and default branch.'),
                  ),
                  DsAccordionItem(
                    value: 'danger',
                    enabled: false,
                    title: Text('Danger zone (owners only)'),
                    child: Text('Transfer or delete the project.'),
                  ),
                ],
              ),
              // #endregion
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one accordion with `style`, or every one in a subtree '
            'with `DsAccordionTheme`. `headerHeight` is a minimum: headers '
            'grow with long titles and large text.',
          ),
          Example(
            snippet: 'accordion-custom',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              // #region accordion-custom
              child: DsAccordion<String>(
                style: DsAccordionStyle(
                  borderRadius: BorderRadius.circular(16),
                  headerHeight: 52,
                  headerPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 20,
                  ),
                  bodyPadding: const EdgeInsetsDirectional.fromSTEB(
                    20,
                    0,
                    20,
                    20,
                  ),
                  iconColor: const Color(0xFF0B6E4F),
                ),
                items: const [
                  DsAccordionItem(
                    value: 'returns',
                    title: Text('Returns'),
                    child: Text('Free returns within 30 days of delivery.'),
                  ),
                  DsAccordionItem(
                    value: 'warranty',
                    title: Text('Warranty'),
                    child: Text('Two years on parts and labor.'),
                  ),
                ],
              ),
              // #endregion
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
              'Moves to the next header; each enabled header is a Tab stop. '
                  'Links and fields inside an open section follow their '
                  'header.',
            ),
            ('Enter / Space', 'Opens or closes the focused section.'),
          ]),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Each header is a button inside a heading, announced as '
                'expanded or collapsed, as in the WAI-ARIA accordion pattern.',
            '`semanticLabel` names the group of sections.',
            'The keyboard focus ring is drawn inside the header, so the '
                'rounded container never clips it.',
            'With reduced motion, sections open without animation.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsAccordion'),
          ApiTable([
            (
              'items',
              'List<DsAccordionItem<T>>',
              'The sections, top to bottom.',
            ),
            (
              'initialValue',
              'Set<T>',
              'Sections open at first build, when uncontrolled.',
            ),
            (
              'value',
              'Set<T>?',
              'The open sections, when controlled; null keeps its own.',
            ),
            (
              'onChanged',
              'ValueChanged<Set<T>>?',
              'Called with the new set of open sections.',
            ),
            (
              'allowMultiple',
              'bool',
              'Whether several sections may be open at once.',
            ),
            ('semanticLabel', 'String?', 'Names the group of sections.'),
            ('style', 'DsAccordionStyle?', 'Laid over the theme and defaults.'),
          ]),
          DocHeading('DsAccordionItem'),
          ApiTable([
            ('value', 'T', 'Identifies the section; unique in the accordion.'),
            ('title', 'Widget', 'The header, usually a short `Text`.'),
            ('child', 'Widget', 'The content shown while open.'),
            ('enabled', 'bool', 'Whether the section can be toggled.'),
          ]),
        ],
      ),
    ],
  );
}

class _ControlledDemo extends StatefulWidget {
  const _ControlledDemo();

  @override
  State<_ControlledDemo> createState() => _ControlledDemoState();
}

class _ControlledDemoState extends State<_ControlledDemo> {
  static const _all = {'api', 'webhooks', 'audit'};
  Set<String> _open = {'api'};

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Wrap(
          spacing: 8,
          children: [
            DsButton(
              variant: DsButtonVariant.secondary,
              size: DsSize.sm,
              onPressed: _open.length == _all.length
                  ? null
                  : () => setState(() => _open = {..._all}),
              child: const Text('Expand all'),
            ),
            DsButton(
              variant: DsButtonVariant.ghost,
              size: DsSize.sm,
              onPressed: _open.isEmpty
                  ? null
                  : () => setState(() => _open = {}),
              child: const Text('Collapse all'),
            ),
          ],
        ),
        // #region accordion-controlled
        DsAccordion<String>(
          allowMultiple: true,
          value: _open,
          onChanged: (open) => setState(() => _open = open),
          items: const [
            DsAccordionItem(
              value: 'api',
              title: Text('API keys'),
              child: Text('Two active keys. The oldest was created in March.'),
            ),
            DsAccordionItem(
              value: 'webhooks',
              title: Text('Webhooks'),
              child: Text('Events are sent to one endpoint.'),
            ),
            DsAccordionItem(
              value: 'audit',
              title: Text('Audit log'),
              child: Text('Kept for 90 days on your plan.'),
            ),
          ],
        ),
        // #endregion
      ],
    ),
  );
}
