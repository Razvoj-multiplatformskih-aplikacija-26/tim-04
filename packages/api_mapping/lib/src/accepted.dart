import 'package:domain/domain.dart';

T accepted<T>(Result<T> result) => switch (result) {
  Success(:final value) => value,
  Failure(:final error) => throw FormatException('The contract carried a value the domain rejects', error),
};
