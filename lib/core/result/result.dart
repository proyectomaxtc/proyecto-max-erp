abstract class Result<T> {
  const Result();

  bool get isSuccess;

  bool get isFailure => !isSuccess;
}

class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool get isSuccess => true;
}

class Failure<T> extends Result<T> {
  final String message;

  final Object? error;

  const Failure(
    this.message, {
    this.error,
  });

  @override
  bool get isSuccess => false;
}