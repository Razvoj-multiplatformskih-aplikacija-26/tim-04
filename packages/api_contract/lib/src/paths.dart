abstract final class ApiPaths {
  static const health = '/health';
  static const animals = '/api/v1/animals';
  static const adoptionRequests = '/api/v1/adoption-requests';

  static String animal(String id) => '$animals/$id';

  static String quarantine(String id) => '${animal(id)}/quarantine';

  static String adoptionRequest(String id) => '$adoptionRequests/$id';

  static String withdrawal(String id) => '${adoptionRequest(id)}/withdrawal';

  static String approval(String id) => '${adoptionRequest(id)}/approval';

  static String rejection(String id) => '${adoptionRequest(id)}/rejection';
}

abstract final class ApiQuery {
  static const status = 'status';
  static const species = 'species';
  static const animal = 'animal';
  static const applicant = 'applicant';
}

abstract final class ApiHeaders {
  static const devUser = 'X-Dev-User';
}
