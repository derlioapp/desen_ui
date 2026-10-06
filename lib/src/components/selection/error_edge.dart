import 'package:flutter/widgets.dart';

import '../../theme/theme_data.dart';

/// The error outline color of form controls: the theme's field-error edge,
/// or the danger ink when `adjustShadows` removed it (reading
/// `fieldError.first` crashed on an empty list).
Color dsErrorEdge(DsThemeData theme) =>
    theme.shadows.fieldError.firstOrNull?.color ?? theme.colors.danger.text;
