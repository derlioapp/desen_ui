import 'package:flutter/widgets.dart';

/// One radio or radio card as its `DsRadioGroup` sees it, for the group's
/// keyboard handling: the value it stands for, its focus node and whether
/// it can be selected now.
class RadioGroupMember {
  /// Describes a member through getters, so it always reads the current
  /// widget.
  RadioGroupMember({
    required this.value,
    required this.focusNode,
    required this.enabled,
  });

  /// The value the member stands for.
  final Object? Function() value;

  /// The member's focus node.
  final FocusNode Function() focusNode;

  /// Whether the member can be selected.
  final bool Function() enabled;
}

/// What a `DsRadioGroup` tells the radios and radio cards below it:
/// whether the group is enabled, whether it carries an error, and where
/// they register for the group's arrow, Home and End keys.
class RadioGroupScope extends InheritedWidget {
  /// Scopes [child] to a group.
  const RadioGroupScope({
    super.key,
    required this.enabled,
    required this.error,
    required this.members,
    required this.valueType,
    required super.child,
  });

  /// False when the group's `onChanged` is null.
  final bool enabled;

  /// Whether every radio in the group shows the error look.
  final bool error;

  /// The radios and radio cards of the group; each adds itself while it
  /// is mounted. The set is the group's for its whole life.
  final Set<RadioGroupMember> members;

  /// The group's value type, the `T` of `DsRadioGroup<T>`.
  final Type valueType;

  /// The nearest scope, or null outside a group.
  static RadioGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RadioGroupScope>();

  @override
  bool updateShouldNotify(RadioGroupScope old) =>
      enabled != old.enabled ||
      error != old.error ||
      members != old.members ||
      valueType != old.valueType;
}

/// In debug builds, fails when [option] (a radio or a radio card whose
/// value type is [T]) sits in a `DsRadioGroup` of another value type, so
/// [registry] (what `RadioGroup.maybeOf<T>` found) is null: the group
/// only takes options of exactly its own type, and the option would be
/// inert without a word.
void debugCheckRadioGroupType<T>(
  BuildContext context,
  Widget option,
  Object? registry,
) {
  assert(() {
    if (registry != null) return true;
    final group = context.getInheritedWidgetOfExactType<RadioGroupScope>();
    if (group == null) return true;
    final name = option.runtimeType.toString().split('<').first;
    throw FlutterError.fromParts([
      ErrorSummary(
        'A ${option.runtimeType} is inside a DsRadioGroup<${group.valueType}>.',
      ),
      ErrorDescription(
        'A group only takes options of exactly its own value type, so this '
        'one can never be selected: it would show as disabled.',
      ),
      ErrorHint(
        'Give both the same type argument, e.g. '
        '$name<${group.valueType}>(...) in DsRadioGroup<${group.valueType}>, '
        'or $name<$T>(...) in DsRadioGroup<$T>.',
      ),
    ]);
  }());
}

/// Keeps [member] in the group of the nearest [RadioGroupScope] while it
/// is mounted. Call [update] from `didChangeDependencies` and [dispose]
/// from `dispose`.
class RadioGroupMembership {
  /// Tracks [member].
  RadioGroupMembership(this.member);

  /// The member this tracks.
  final RadioGroupMember member;

  Set<RadioGroupMember>? _members;

  /// Moves [member] to the group above [context], if it changed.
  void update(BuildContext context) {
    final members = RadioGroupScope.maybeOf(context)?.members;
    if (identical(members, _members)) return;
    _members?.remove(member);
    _members = members?..add(member);
  }

  /// Leaves the group.
  void dispose() {
    _members?.remove(member);
    _members = null;
  }
}
