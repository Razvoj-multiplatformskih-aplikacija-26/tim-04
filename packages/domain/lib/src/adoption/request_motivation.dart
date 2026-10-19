import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

@immutable
final class RequestMotivation {
  const RequestMotivation._(this.text);

  static const minLength = 20;
  static const maxLength = 500;

  final String text;

  int get length => text.characters.length;

  static Result<RequestMotivation> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length < minLength) return Failure(MotivationTooShort(length));
    if (length > maxLength) return const Failure(MotivationTooLong());
    return Success(RequestMotivation._(text));
  }

  @override
  bool operator ==(Object other) => other is RequestMotivation && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RequestMotivation("$text")';
}
