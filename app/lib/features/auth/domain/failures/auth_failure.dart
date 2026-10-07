sealed class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cause, this.stackTrace});

  final String message;

  /// Original exception when this failure wraps a lower-level error.
  final Object? cause;

  /// Stack trace of [cause], when available.
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (cause == null) {
      return message;
    }
    return '$message\nCaused by: $cause';
  }
}

final class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure() : super('Este email ya está registrado');
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Contraseña incorrecta');
}

final class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('Usuario no encontrado');
}

final class NetworkUnavailableFailure extends AuthFailure {
  const NetworkUnavailableFailure() : super('Sin conexión a internet');
}

final class ValidationFailure extends AuthFailure {
  const ValidationFailure(super.message);
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([
    super.message = 'Ha ocurrido un error inesperado',
  ]);

  const UnknownAuthFailure.wrap(
    super.message, {
    required Object cause,
    super.stackTrace,
  }) : super(cause: cause);
}

final class RequiresRecentLoginFailure extends AuthFailure {
  const RequiresRecentLoginFailure()
    : super('Por seguridad, confirma tu identidad para continuar.');
}

final class ReauthCancelledFailure extends AuthFailure {
  const ReauthCancelledFailure() : super('Reautenticación cancelada');
}

final class AccountExistsWithDifferentCredentialFailure extends AuthFailure {
  const AccountExistsWithDifferentCredentialFailure({required this.email})
    : super('Ya existe una cuenta con este email. Introduce tu contraseña.');

  final String email;
}

final class GoogleAccountAlreadyExistsFailure extends AuthFailure {
  const GoogleAccountAlreadyExistsFailure()
    : super(
        'Ya tienes una cuenta con Google. Inicia sesión con Google directamente.',
      );
}
