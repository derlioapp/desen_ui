/// How much the controls answer a touch through the device's haptic engine,
/// set once for the whole app on `DsThemeData.haptics`.
///
/// The values are a ladder, not an on/off pair, because the platforms draw
/// their line in the middle: iOS and Android tick when a switch flips or a
/// picker moves, and neither vibrates on every button press. [subtle] is
/// that platform behavior; [full] is the louder choice; [none] is silence.
///
/// Haptics answer a touch: Desen's controls play them for taps and drags,
/// not for keyboard or screen reader activation, as on iOS. Desktop
/// platforms have no haptic engine, so they stay silent whatever the
/// setting.
enum DsHaptics {
  /// No haptics. The default on the web and on desktop.
  none,

  /// State changes only: a checkbox or switch flipping, a radio, tab,
  /// segment, chip or navigation item becoming the selected one, a stepped
  /// slider crossing a step, a stepper changing its value, an option or a
  /// day being picked, and an app's control reaching a milestone. A control
  /// that only issues a command (a button, a menu item) stays silent. The
  /// default in iOS and Android apps.
  subtle,

  /// State changes and command presses: every enabled press of a
  /// `DsPressable` plays.
  ///
  /// Not the default: a device that answers every tap the same way stops
  /// saying anything with it, and a press already shows itself.
  full;

  /// Whether [event] plays under this setting.
  bool plays(DsHapticEvent event) => switch (this) {
    DsHaptics.none => false,
    DsHaptics.subtle => event != DsHapticEvent.command,
    DsHaptics.full => true,
  };
}

/// What a control is doing when it asks for haptic feedback. Components name
/// the event; [DsHaptics] decides whether it plays and `DsHapticFeedback`
/// decides how it feels.
enum DsHapticEvent {
  /// The control's own state changed: a toggle flipped, a selection moved,
  /// a value stepped. Plays as the platform's selection tick under
  /// [DsHaptics.subtle] and [DsHaptics.full].
  selection,

  /// The control issued a command and holds no state of its own, e.g. a
  /// button. Plays as a light impact under [DsHaptics.full] only.
  command,

  /// The control reached a point the user is counting toward: a counter
  /// its step or its goal, a long hold its end. Plays as the platform's
  /// success notification, heavier than [selection], under
  /// [DsHaptics.subtle] and [DsHaptics.full].
  ///
  /// Desen's own controls never play it: an app's control plays it with
  /// `DsHapticFeedback.play` when the milestone is reached, not on every
  /// step toward it (those are [selection]). Played often, it stops meaning
  /// anything.
  milestone,
}
