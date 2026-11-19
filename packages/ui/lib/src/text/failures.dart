import 'package:use_cases/use_cases.dart';

String failureMessage(Object cause, {String fallback = 'Učitavanje nije uspelo.'}) => switch (cause) {
  RepositoryException(failure: RepositoryFailure.unreachable) => 'Nema veze sa serverom.',
  RepositoryException(failure: RepositoryFailure.serverError) => 'Greška na serveru.',
  RepositoryException(failure: RepositoryFailure.refused) => 'Server nije prihvatio zahtev.',
  RepositoryException(failure: RepositoryFailure.sessionExpired) => 'Sesija je istekla. Prijavite se ponovo.',
  _ => fallback,
};
