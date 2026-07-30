/// Exceptions thrown at the data-source layer (network, local DB, cache).
///
/// These are caught by repositories and mapped to [Failure]s before ever
/// reaching the presentation layer — screens/providers should never see a
/// raw exception.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);
  final String message;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class ValidationException implements Exception {
  const ValidationException(this.message, {this.fieldErrors});
  final String message;
  final Map<String, String>? fieldErrors;
}

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
}
