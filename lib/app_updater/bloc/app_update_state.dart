/// Base class for all states emitted by [AppUpdateBloc].
abstract class AppUpdateState {
  const AppUpdateState();
}

/// Initial state before any initialization or check has occurred.
class AppUpdateInitial extends AppUpdateState {
  const AppUpdateInitial();

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppUpdateInitial;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AppUpdateInitial()';
}

/// State emitted while actively querying the remote AppCast feed.
class AppUpdateChecking extends AppUpdateState {
  const AppUpdateChecking({required this.isManual});

  /// Whether this check was initiated manually by the user or in background.
  final bool isManual;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUpdateChecking && other.isManual == isManual;

  @override
  int get hashCode => isManual.hashCode;

  @override
  String toString() => 'AppUpdateChecking(isManual: $isManual)';
}

/// State emitted when the check operation finishes successfully.
class AppUpdateCheckSuccess extends AppUpdateState {
  const AppUpdateCheckSuccess({
    required this.isManual,
    this.timestamp,
  });

  final bool isManual;
  final DateTime? timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUpdateCheckSuccess && other.isManual == isManual;

  @override
  int get hashCode => isManual.hashCode;

  @override
  String toString() => 'AppUpdateCheckSuccess(isManual: $isManual)';
}

/// State emitted if the update check encountered an error (network error, invalid feed, etc.).
class AppUpdateCheckFailure extends AppUpdateState {
  const AppUpdateCheckFailure({
    required this.message,
    required this.isManual,
  });

  final String message;
  final bool isManual;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUpdateCheckFailure &&
          other.message == message &&
          other.isManual == isManual;

  @override
  int get hashCode => Object.hash(message, isManual);

  @override
  String toString() =>
      'AppUpdateCheckFailure(message: $message, isManual: $isManual)';
}
