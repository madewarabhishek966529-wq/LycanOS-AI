import 'package:equatable/equatable.dart';

/// Failures are the presentation-layer-facing counterpart to the
/// data-layer's [Exception]s. Repositories return `Either<Failure, T>`
/// (or a `Result<T>` in the leaner form used here) so providers can render
/// error states without ever handling raw exceptions or stack traces.
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors});
  final Map<String, String>? fieldErrors;
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}

/// Lightweight Result type used across repository interfaces instead of
/// pulling in `dartz` — keeps the dependency surface small while still
/// forcing callers to handle both branches explicitly.
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
