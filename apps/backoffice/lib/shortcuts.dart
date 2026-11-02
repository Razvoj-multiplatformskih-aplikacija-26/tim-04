import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool get usesCommandKey => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

String get commandKeyLabel => usesCommandKey ? '⌘' : 'Ctrl';

/// A [CallbackAction] that only runs when [enabled] says so, e.g. "approve" only when there is a pending request.
class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

/// ↑ / ↓: select the previous (-1) or next (+1) animal in the table.
class MoveSelectionIntent extends Intent {
  const MoveSelectionIntent(this.offset);

  final int offset;
}

/// →: move the keyboard focus from the table into the details panel.
class FocusDetailsIntent extends Intent {
  const FocusDetailsIntent();
}

/// ←: move the keyboard focus from the details panel back to the table.
class FocusTableIntent extends Intent {
  const FocusTableIntent();
}

/// Esc: close the details panel.
class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

/// Ctrl+Enter: approve the oldest pending request of the selected animal.
class ApproveIntent extends Intent {
  const ApproveIntent();
}

/// Ctrl+N: open the intake form for a new animal.
class IntakeIntent extends Intent {
  const IntakeIntent();
}

/// F1: show the list of shortcuts.
class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

SingleActivator _command(LogicalKeyboardKey key) =>
    SingleActivator(key, meta: usesCommandKey, control: !usesCommandKey);

Map<ShortcutActivator, Intent> animalsShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveSelectionIntent(-1),
  const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveSelectionIntent(1),
  const SingleActivator(LogicalKeyboardKey.arrowRight): const FocusDetailsIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowLeft): const FocusTableIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
  _command(LogicalKeyboardKey.enter): const ApproveIntent(),
  _command(LogicalKeyboardKey.keyN): const IntakeIntent(),
  const SingleActivator(LogicalKeyboardKey.f1): const ShowShortcutsIntent(),
};

/// Inside the details panel ↑ / ↓ go from button to button instead of changing the animal.
Map<ShortcutActivator, Intent> detailsShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
};

final class ShortcutDescription {
  const ShortcutDescription(this.keys, this.description);

  final String keys;
  final String description;
}

List<ShortcutDescription> shortcutDescriptions() => [
  const ShortcutDescription('↑ ↓', 'Prethodna / sledeća životinja'),
  const ShortcutDescription('→  /  ←', 'U detalje / nazad u tabelu'),
  const ShortcutDescription('↑ ↓ u detaljima', 'Kretanje kroz dugmad u detaljima'),
  const ShortcutDescription('Tab', 'Kretanje kroz dugmad i polja'),
  const ShortcutDescription('Enter', 'Pritisni dugme ili red pod fokusom'),
  const ShortcutDescription('Esc', 'Zatvori detalje'),
  ShortcutDescription('$commandKeyLabel Enter', 'Odobri najstariji zahtev na čekanju'),
  ShortcutDescription('$commandKeyLabel N', 'Prijem nove životinje'),
  const ShortcutDescription('F1', 'Pregled prečica'),
];
