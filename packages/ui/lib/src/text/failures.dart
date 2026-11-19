import 'package:use_cases/use_cases.dart';

const serverUnreachableMessage = 'Nema veze sa serverom.';
const sessionExpiredMessage = 'Sesija je istekla. Prijavite se ponovo.';

String failureMessage(Object cause, {String fallback = 'Učitavanje nije uspelo.'}) => switch (cause) {
  RepositoryException(failure: RepositoryFailure.unreachable) => serverUnreachableMessage,
  RepositoryException(failure: RepositoryFailure.serverError) => 'Greška na serveru.',
  RepositoryException(failure: RepositoryFailure.refused) => 'Server nije prihvatio zahtev.',
  RepositoryException(failure: RepositoryFailure.sessionExpired) => sessionExpiredMessage,
  _ => fallback,
};
