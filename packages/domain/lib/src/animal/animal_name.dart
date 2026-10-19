import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class AnimalName {
  const AnimalName._(this.text);

  static const minLength = 2;
  static const maxLength = 40;

  final String text;

  int get length => text.characters.length;

  static Result<AnimalName> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length < minLength) return const Failure(NameTooShort());
    if (length > maxLength) return const Failure(NameTooLong());
    return Success(AnimalName._(text));
  }

  @override
  bool operator ==(Object other) => other is AnimalName && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'AnimalName("$text")';
}
