import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';

/// Maps Firebase Auth error codes to domain [AuthFailure]s with user-facing
/// Spanish messages. Kept free of the Firebase SDK so it is unit-testable.
AuthFailure mapFirebaseAuthErrorCode(String code) {
  return switch (code) {
    'email-already-in-use' => const EmailAlreadyInUseFailure(),
    'user-not-found' => const UserNotFoundFailure(),
    'wrong-password' || 'invalid-credential' =>
      const InvalidCredentialsFailure(),
    'invalid-email' => const ValidationFailure('Email no válido'),
    'user-disabled' => const UnknownAuthFailure('Cuenta desactivada'),
    'network-request-failed' => const NetworkUnavailableFailure(),
    'too-many-requests' => const UnknownAuthFailure(
      'Demasiados intentos. Espera unos minutos',
    ),
    'weak-password' => const ValidationFailure(
      'La contraseña es demasiado débil. Elige una más segura.',
    ),
    'operation-not-allowed' => const UnknownAuthFailure(
      'Esta forma de acceso no está disponible ahora mismo.',
    ),
    _ => UnknownAuthFailure(
      'Ha ocurrido un error inesperado ($code)',
    ),
  };
}

/// Maps Firebase Auth codes for the password-reset flow.
AuthFailure mapFirebasePasswordResetErrorCode(String code) {
  return switch (code) {
    'user-not-found' => const UserNotFoundFailure(),
    'invalid-email' => const ValidationFailure('Email no válido'),
    'network-request-failed' => const NetworkUnavailableFailure(),
    'too-many-requests' => const UnknownAuthFailure(
      'Demasiados intentos. Espera unos minutos',
    ),
    'user-disabled' => const UnknownAuthFailure('Cuenta desactivada'),
    _ => UnknownAuthFailure(
      'Ha ocurrido un error inesperado ($code)',
    ),
  };
}
