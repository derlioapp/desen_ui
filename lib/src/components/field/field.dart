import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../icons/icon.dart';
import '../../icons/icons.dart';
import '../../l10n/localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/theme.dart';
import '../../theme/theme_data.dart';
import 'field_style.dart';

/// A form field's frame: a label above the control, a description or an
/// error message below it, and a required mark (the message
/// belongs to the field or the group, not to each control).
///
/// ```dart
/// DsField(
///   label: const Text('Proje'),
///   description: const Text('Raporlar bu projeye bağlanır.'),
///   errorText: project == null ? 'Bir proje seçin.' : null,
///   required: true,
///   child: DsSelect<String>(
///     value: project,
///     onChanged: (v) => setState(() => project = v),
///     options: options,
///   ),
/// )
/// ```
///
/// **Error.** A non-null [errorText] replaces the description with a status
/// icon and the message in the danger text color: the error is told in
/// text, not by color (WCAG 3.3.1). Desen's controls inside (text
/// field, select, checkbox, radio) take the error look from the field
/// through [DsFieldScope]; no second `error: true` is needed. The message
/// area grows and shrinks on the tone spring, which does not overshoot, so
/// the content below does not bounce.
///
/// **Screen readers.** By default the field and its control are one node:
/// the label names the control, followed by the control's own label and
/// value, then the description or the error; the node is marked required
/// and, with an error, invalid. A [group] keeps the controls as separate
/// nodes (a group of checkboxes or radios): the label, then the controls,
/// then the message, each read in order. When an error appears or changes
/// it is announced politely: as an announcement where the platform
/// supports them ([MediaQueryData.supportsAnnounce]), else (Android) as a
/// polite live region, never both. The required mark is read as the
/// localized "Required", not as an asterisk.
///
/// A control with buttons of its own (a text field's clear or show
/// password button) asks the field, through [DsFieldHooks], to keep them
/// as separate nodes: the control's node is then named by the label's
/// text (a [Text] label) and the message follows as its own node.
///
/// **Input issues.** A date, time or number field that holds text which
/// is not a value tells the field how to fix it
/// ([DsFieldHooks.setInputIssue]); without an [errorText] of its own the field
/// shows that message as its error, so the error look always comes with
/// text (WCAG 3.3.1). An [errorText] given by the app wins.
///
/// **Message row.** A control can show something at the end of the
/// message row, e.g. a text field's character counter; the description or
/// the error stays at the start, on the same row.
///
/// Works without `DsScope`, in RTL and with large text.
class DsField extends StatefulWidget {
  /// Creates a field around [child].
  const DsField({
    super.key,
    this.label,
    this.description,
    this.errorText,
    this.required = false,
    this.group = false,
    this.style,
    required this.child,
  });

  /// What the field asks for, above the control; usually a [Text].
  final Widget? label;

  /// A hint below the control, e.g. a format or why it is asked; usually
  /// a [Text]. Hidden while there is an [errorText].
  final Widget? description;

  /// The validation message, or null when the value is valid.
  final String? errorText;

  /// Marks the field required: a mark after the label, read as "Required",
  /// and the required state for screen readers.
  final bool required;

  /// Whether [child] holds several controls (checkboxes, radios) that keep
  /// their own semantics nodes, instead of one control the label names.
  final bool group;

  /// Style laid over the theme and defaults.
  final DsFieldStyle? style;

  /// The control, or for a [group] the controls.
  final Widget child;

  /// Desen's default field style under [theme].
  static DsFieldStyle defaultStyle(DsThemeData theme) {
    final k = theme.colors;
    return DsFieldStyle(
      labelStyle: theme.typography.fieldLabel.copyWith(color: k.textMuted),
      requiredColor: k.danger.text,
      messageStyle: theme.typography.caption.copyWith(color: k.textSubtle),
      iconColor: k.danger.text,
      iconSize: 12,
      labelGap: DsSpace.s6,
      messageGap: DsSpace.s6,
      gap: DsSpace.s4,
      error: DsFieldStyle(messageStyle: TextStyle(color: k.danger.text)),
    );
  }

  @override
  State<DsField> createState() => _DsFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('group', value: group, ifTrue: 'group'))
      ..add(DiagnosticsProperty('style', style, defaultValue: null));
  }
}

class _DsFieldState extends State<DsField> {
  final _hooks = DsFieldHooks._();

  /// The control's input issue shown last.
  String? _issue;

  @override
  void initState() {
    super.initState();
    _hooks._notifier.addListener(_onHooks);
  }

  @override
  void dispose() {
    _hooks._notifier.removeListener(_onHooks);
    _hooks._dispose();
    super.dispose();
  }

  void _onHooks() {
    final issue = _hooks.inputIssue;
    if (issue == _issue || !mounted) return;
    _issue = issue;
    if (widget.errorText == null && issue != null) _announce(issue);
    setState(() {});
  }

  /// A new or changed message is announced, politely (where the platform
  /// announces; elsewhere the message area is a live region).
  void _announce(String error) {
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    // A form that validated announces its first error itself.
    if (context.getInheritedWidgetOfExactType<DsFieldQuietScope>()?.quiet ??
        false) {
      return;
    }
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        [DsLocalizations.of(context).error, error].join('\n'),
        Directionality.of(context),
      ),
    );
  }

  /// The message shown: the app's, else the control's input issue.
  String? get _error => widget.errorText ?? _issue;

  @override
  void didUpdateWidget(DsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = _error;
    // A new or changed message is announced, politely; one that is there
    // from the start is read with the field instead.
    if (error != null && error != (oldWidget.errorText ?? _issue)) {
      _announce(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = dsThemeOf(context);
    final l10n = DsLocalizations.of(context);
    final error = _error;
    final hasError = error != null;
    final s = DsFieldStyle.resolveLayers(
      [DsField.defaultStyle(t), DsFieldTheme.of(context).style, widget.style],
      {if (hasError) WidgetState.error},
    );
    final gap = s.gap!;

    Widget? label;
    if (widget.label case final text?) {
      label = DefaultTextStyle.merge(
        style: s.labelStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: gap,
          children: [
            Flexible(child: text),
            if (widget.required)
              // The shape marks it; screen readers hear the word.
              Semantics(
                label: l10n.required,
                child: ExcludeSemantics(
                  // ds-raw: the mark; its spoken name is l10n.required
                  child: Text('*', style: TextStyle(color: s.requiredColor)),
                ),
              ),
          ],
        ),
      );
    }

    Widget? message;
    if (error != null) {
      final iconSize = MediaQuery.textScalerOf(context).scale(s.iconSize!);
      // Read as "Error, <message>": the status first, as the icon shows it
      // (a placeholder's own node would be read after the text).
      message = Semantics(
        label: [l10n.error, error].join('\n'),
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: gap),
                  child: DsIcon(
                    DsIcons.circleAlert,
                    size: iconSize,
                    color: s.iconColor,
                  ),
                ),
              ),
              TextSpan(text: error),
            ],
          ),
          style: s.messageStyle,
        ),
      );
    } else if (widget.description case final description?) {
      message = DefaultTextStyle.merge(
        style: s.messageStyle,
        child: description,
      );
    }
    if (message != null) {
      message = Padding(
        padding: EdgeInsetsDirectional.only(top: s.messageGap!),
        child: message,
      );
    }

    final motion = t.motion;
    // The description and the error swap with a fade while the area
    // resizes on the tone spring: no overshoot that would shake the
    // content below (K-46, as the accordion).
    final switcher = AnimatedSwitcher(
      duration: motion.toneDuration,
      switchInCurve: motion.toneCurve,
      switchOutCurve: motion.toneCurve,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          // A leaving message is not read again.
          for (final p in previous) ExcludeSemantics(child: p),
          ?current,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey<Object?>(hasError ? (error,) : message != null),
        child: message ?? const SizedBox.shrink(),
      ),
    );
    // With reduce motion the size jumps. (AnimatedSize with a zero
    // duration re-dirties itself during layout, so it is left out.)
    final messageArea = motion.reduced
        ? switcher
        : AnimatedSize(
            duration: motion.toneDuration,
            curve: motion.toneCurve,
            alignment: AlignmentDirectional.topStart,
            child: switcher,
          );

    // Without announcements (Android) the error area is a polite live
    // region: it speaks when the message appears or changes.
    final live = hasError && !MediaQuery.supportsAnnounceOf(context);
    final labelText = switch (widget.label) {
      final Text text => text.data ?? text.textSpan?.toPlainText(),
      _ => null,
    };
    final scope = DsFieldScope(
      // The app's error: a control's own issue marks only that control.
      hasError: widget.errorText != null,
      isRequired: widget.required,
      isLabelled: !widget.group && widget.label != null,
      labelText: widget.group ? null : labelText,
      hooks: _hooks,
      child: widget.child,
    );
    // The end of the message row, e.g. a text field's counter, beside the
    // description or the error.
    final messageRow = ListenableBuilder(
      listenable: _hooks._notifier,
      builder: (context, _) {
        final end = _hooks._end;
        if (end == null) return messageArea;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [
            Expanded(child: messageArea),
            Padding(
              padding: EdgeInsetsDirectional.only(top: s.messageGap!),
              child: end,
            ),
          ],
        );
      },
    );

    if (widget.group) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: EdgeInsetsDirectional.only(bottom: s.labelGap!),
                child: Semantics(container: true, child: label),
              ),
            scope,
            Semantics(container: true, liveRegion: live, child: messageRow),
          ],
        ),
      );
    }
    // One node, unless the control keeps its own buttons apart; then the
    // control is named by the label's text and the message is its own
    // node (live on Android, as in a group).
    return _FieldSemantics(
      hooks: _hooks,
      isRequired: widget.required,
      invalid: hasError,
      live: live,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: s.labelGap!),
              child: _FieldPartSemantics(
                hooks: _hooks,
                // A label whose text the control took is not read twice.
                excludeWhenSeparate: labelText != null,
                child: label,
              ),
            ),
          scope,
          _FieldPartSemantics(
            hooks: _hooks,
            liveWhenSeparate: live,
            child: messageRow,
          ),
        ],
      ),
    );
  }
}

/// Internal (hidden from the package exports): keeps the [DsField]s below
/// from announcing a new error while [quiet]. A `DsFormField` sets it for
/// the frame after a `Form` validated, since Flutter's `FormState` then
/// announces the first error itself; one announcement, not one per field.
class DsFieldQuietScope extends InheritedWidget {
  /// Quiets the fields in [child] while [quiet].
  const DsFieldQuietScope({
    super.key,
    required this.quiet,
    required super.child,
  });

  /// Whether the fields below leave error announcements out.
  final bool quiet;

  @override
  bool updateShouldNotify(DsFieldQuietScope oldWidget) => false;
}

/// What a [DsField] tells the controls inside it.
///
/// Controls read it to take the field's error look without a second
/// `error: true`, and to leave naming to the field's label: Desen's text
/// field, select, checkbox and radio do.
class DsFieldScope extends InheritedWidget {
  /// Provides field state to [child].
  const DsFieldScope({
    super.key,
    required this.hasError,
    required this.isRequired,
    required this.isLabelled,
    this.labelText,
    this.hooks,
    required super.child,
  });

  /// Whether the field shows an error.
  final bool hasError;

  /// Whether the field is required.
  final bool isRequired;

  /// Whether the field's label names the control (a single-control field
  /// with a label): the control need not add a label of its own.
  final bool isLabelled;

  /// The label as plain text when the field's label is a [Text]; a control
  /// that keeps its own buttons apart ([DsFieldHooks.separateNodes]) names
  /// its node with it.
  final String? labelText;

  /// What the control can tell the field; null for a scope built by hand.
  final DsFieldHooks? hooks;

  /// The nearest field scope, or null outside a [DsField].
  static DsFieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DsFieldScope>();

  @override
  bool updateShouldNotify(DsFieldScope oldWidget) =>
      hasError != oldWidget.hasError ||
      isRequired != oldWidget.isRequired ||
      isLabelled != oldWidget.isLabelled ||
      labelText != oldWidget.labelText ||
      hooks != oldWidget.hooks;
}

/// What a control tells the [DsField] around it, reached through
/// [DsFieldScope.hooks]. Call the setters from the control's `build`; the
/// field picks the change up in the same frame when it has not laid out
/// its message row yet, else right after it.
final class DsFieldHooks {
  DsFieldHooks._();

  /// Tells the field (and its semantics) that something changed.
  final _notifier = _HooksNotifier();

  Widget? _end;
  Object? _endKey;
  final _issues = <Object, String>{};
  bool _separate = false;
  bool _scheduled = false;
  bool _disposed = false;

  /// Whether the control keeps its own buttons as separate semantics nodes.
  bool get separateNodes => _separate;

  /// Shows [end] at the end of the field's message row (null removes it),
  /// e.g. a character counter. [key] identifies what [end] shows: the row
  /// rebuilds only when it changes, so [end] should follow its own data
  /// (a counter listens to the text).
  void setMessageEnd(Widget? end, {Object? key}) {
    final changed = (end == null) != (_end == null) || key != _endKey;
    _end = end;
    _endKey = key;
    if (changed) _changed();
  }

  /// The message of the input issue a control inside reported last
  /// ([setInputIssue]), or null.
  String? get inputIssue => _issues.isEmpty ? null : _issues.values.last;

  /// Tells the field that [control]'s typed text is not a value, with [message]
  /// saying how to fix it; null when the text is a value or empty again.
  /// Without an `errorText` of its own the field shows the message as its error
  /// ([DsField.errorText]). [control] is any object the control keeps (its
  /// state), so several controls in a group report apart.
  void setInputIssue(Object control, String? message) {
    final before = inputIssue;
    _issues.remove(control);
    if (message != null) _issues[control] = message;
    if (inputIssue != before) _changed();
  }

  /// Keeps the control's own buttons as separate semantics nodes instead of
  /// merging the field into one node: the control names itself with
  /// [DsFieldScope.labelText] and the message follows as its own node.
  set separateNodes(bool value) {
    if (value == _separate) return;
    _separate = value;
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    // A control's build runs while the field's message row may already
    // be built in this frame: tell it after the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_scheduled) return;
      _scheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (!_disposed) _notifier.notify();
      });
      return;
    }
    _notifier.notify();
  }

  void _dispose() {
    _disposed = true;
    _notifier.dispose();
  }
}

class _HooksNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// The field's node: merges label, control and message into one, unless
/// the control keeps its buttons apart ([DsFieldHooks.separateNodes]).
class _FieldSemantics extends SingleChildRenderObjectWidget {
  const _FieldSemantics({
    required this.hooks,
    required this.isRequired,
    required this.invalid,
    required this.live,
    super.child,
  });

  final DsFieldHooks hooks;
  final bool isRequired;
  final bool invalid;
  final bool live;

  @override
  _RenderFieldSemantics createRenderObject(BuildContext context) =>
      _RenderFieldSemantics(hooks)
        ..isRequired = isRequired
        ..invalid = invalid
        ..live = live;

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFieldSemantics renderObject,
  ) => renderObject
    ..hooks = hooks
    ..isRequired = isRequired
    ..invalid = invalid
    ..live = live;
}

/// Follows a [DsFieldHooks] for semantics.
mixin _HooksSemantics on RenderProxyBox {
  DsFieldHooks get _hooks;
  set _hooks(DsFieldHooks value);

  set hooks(DsFieldHooks value) {
    if (value == _hooks) return;
    if (attached) _hooks._notifier.removeListener(markNeedsSemanticsUpdate);
    _hooks = value;
    if (attached) value._notifier.addListener(markNeedsSemanticsUpdate);
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _hooks._notifier.addListener(markNeedsSemanticsUpdate);
  }

  @override
  void detach() {
    _hooks._notifier.removeListener(markNeedsSemanticsUpdate);
    super.detach();
  }
}

class _RenderFieldSemantics extends RenderProxyBox with _HooksSemantics {
  _RenderFieldSemantics(this._hooks);

  @override
  DsFieldHooks _hooks;

  bool _isRequired = false;
  set isRequired(bool value) {
    if (value == _isRequired) return;
    _isRequired = value;
    markNeedsSemanticsUpdate();
  }

  bool _invalid = false;
  set invalid(bool value) {
    if (value == _invalid) return;
    _invalid = value;
    markNeedsSemanticsUpdate();
  }

  bool _live = false;
  set live(bool value) {
    if (value == _live) return;
    _live = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (_hooks.separateNodes) {
      config.explicitChildNodes = true;
      return;
    }
    config
      ..isMergingSemanticsOfDescendants = true
      ..validationResult = _invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none;
    if (_isRequired) config.isRequired = true;
    if (_live) config.liveRegion = true;
  }
}

/// The label or the message of a field whose control keeps its buttons
/// apart: the label is left out when the control took its text, the
/// message becomes its own node.
class _FieldPartSemantics extends SingleChildRenderObjectWidget {
  const _FieldPartSemantics({
    required this.hooks,
    this.excludeWhenSeparate = false,
    this.liveWhenSeparate = false,
    super.child,
  });

  final DsFieldHooks hooks;
  final bool excludeWhenSeparate;
  final bool liveWhenSeparate;

  @override
  _RenderFieldPartSemantics createRenderObject(BuildContext context) =>
      _RenderFieldPartSemantics(hooks)
        ..exclude = excludeWhenSeparate
        ..live = liveWhenSeparate;

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFieldPartSemantics renderObject,
  ) => renderObject
    ..hooks = hooks
    ..exclude = excludeWhenSeparate
    ..live = liveWhenSeparate;
}

class _RenderFieldPartSemantics extends RenderProxyBox with _HooksSemantics {
  _RenderFieldPartSemantics(this._hooks);

  @override
  DsFieldHooks _hooks;

  bool _exclude = false;
  set exclude(bool value) {
    if (value == _exclude) return;
    _exclude = value;
    markNeedsSemanticsUpdate();
  }

  bool _live = false;
  set live(bool value) {
    if (value == _live) return;
    _live = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_exclude && _hooks.separateNodes) return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (!_hooks.separateNodes || _exclude) return;
    config.isSemanticBoundary = true;
    if (_live) config.liveRegion = true;
  }
}
