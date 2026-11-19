import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool get usesCommandKey => defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

String get commandKeyLabel => usesCommandKey ? '⌘' : 'Ctrl';

class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

class MoveSelectionIntent extends Intent {
  const MoveSelectionIntent(this.offset);

  final int offset;
}

class FocusDetailsIntent extends Intent {
  const FocusDetailsIntent();
}

class FocusTableIntent extends Intent {
  const FocusTableIntent();
}

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class ApproveIntent extends Intent {
  const ApproveIntent();
}

class IntakeIntent extends Intent {
  const IntakeIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
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
  const SingleActivator(LogicalKeyboardKey.f5): const RefreshIntent(),
};

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
  const ShortcutDescription('F5', 'Osveži podatke sa servera'),
  const ShortcutDescription('F1', 'Pregled prečica'),
];
