import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/data/auth_error_mapper.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';

void main() {
  group('mapFirebaseAuthErrorCode', () {
    test('maps user-not-found', () {
      expect(
        mapFirebaseAuthErrorCode('user-not-found'),
        isA<UserNotFoundFailure>(),
      );
      expect(
        mapFirebaseAuthErrorCode('user-not-found').message,
        'Usuario no encontrado',
      );
    });

    test('maps wrong-password and invalid-credential', () {
      for (final code in ['wrong-password', 'invalid-credential']) {
        expect(mapFirebaseAuthErrorCode(code), isA<InvalidCredentialsFailure>());
        expect(
          mapFirebaseAuthErrorCode(code).message,
          'Contraseña incorrecta',
        );
      }
    });

    test('maps invalid-email', () {
      final failure = mapFirebaseAuthErrorCode('invalid-email');
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Email no válido');
    });

    test('maps user-disabled', () {
      expect(
        mapFirebaseAuthErrorCode('user-disabled').message,
        'Cuenta desactivada',
      );
    });

    test('maps network-request-failed', () {
      expect(
        mapFirebaseAuthErrorCode('network-request-failed'),
        isA<NetworkUnavailableFailure>(),
      );
      expect(
        mapFirebaseAuthErrorCode('network-request-failed').message,
        'Sin conexión a internet',
      );
    });

    test('maps too-many-requests', () {
      expect(
        mapFirebaseAuthErrorCode('too-many-requests').message,
        'Demasiados intentos. Espera unos minutos',
      );
    });

    test('maps unknown codes to UnknownAuthFailure with descriptive message', () {
      final failure = mapFirebaseAuthErrorCode('some-unknown-code');
      expect(failure, isA<UnknownAuthFailure>());
      expect(failure.message, isNot(equals('Ha ocurrido un error inesperado')));
      expect(failure.message, contains('some-unknown-code'));
    });
  });
}
