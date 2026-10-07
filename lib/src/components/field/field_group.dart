/// Internal: how a control that holds its options in a semantics node of
/// its own takes the label of the field around it. Not exported from the
/// package.
library;

import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/widgets.dart';

import 'field.dart';

/// What the node that holds a control's options carries from the [DsField]
/// around it: its name, its hint, and the field's required and invalid
/// states.
typedef FieldGroupSemantics = ({
  String? label,
  String? hint,
  bool? isRequired,
  SemanticsValidationResult validationResult,
});

/// Names the node that holds a control's options (a radio group, a
/// segmented control's segments, choice chips, tabs) after the [DsField]
/// around it.
///
/// In a single control's field the options keep their own nodes instead of
/// merging into the field's ([DsFieldHooks.separateNodes]), and the node
/// takes the field's label and message; in a [DsField.group] it takes the
/// group's ([DsFieldHooks.namesGroup]). Call [read] from `build` and
/// [dispose] from `dispose`.
class FieldGroupNaming {
  DsFieldHooks? _hooks;

  /// Tells the field around [context] that the control names its own node,
  /// and returns what that node carries; [semanticLabel] is the control's
  /// own name, after the field's label.
  FieldGroupSemantics read(BuildContext context, {String? semanticLabel}) {
    final scope = DsFieldScope.maybeOf(context);
    final hooks = scope?.hooks;
    if (hooks != _hooks) {
      _release();
      _hooks = hooks;
    }
    // A field that is not a group reads only the first, a group only the
    // second.
    hooks
      ?..separateNodes = true
      ..namesGroup = true;
    final label = [
      ?(scope?.labelText ?? scope?.groupLabelText),
      ?semanticLabel,
    ];
    return (
      label: label.isEmpty ? null : label.join('\n'),
      hint: scope?.messageText ?? scope?.groupMessageText,
      isRequired: (scope?.isRequired ?? false) ? true : null,
      validationResult: (scope?.hasError ?? false)
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
    );
  }

  /// Leaves the field's label and message to it again.
  void dispose() => _release();

  void _release() {
    _hooks
      ?..separateNodes = false
      ..namesGroup = false;
  }
}
