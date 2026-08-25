import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/link_google_account_with_password_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'link_google_account_with_password_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  group('LinkGoogleAccountWithPasswordUseCase', () {
    late MockAuthRepository repository;
    late LinkGoogleAccountWithPasswordUseCase useCase;

    final profile = UserProfile(
      uid: 'uid-1',
      displayName: 'Ana',
      email: 'ana@example.com',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    setUp(() {
      repository = MockAuthRepository();
      useCase = LinkGoogleAccountWithPasswordUseCase(repository);
    });

    test('returns profile when repository links successfully', () async {
      when(
        repository.linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'secret1',
        ),
      ).thenAnswer((_) async => profile);

      final result = await useCase(
        email: 'ana@example.com',
        password: 'secret1',
      );

      expect(result, profile);
      verify(
        repository.linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'secret1',
        ),
      ).called(1);
    });

    test('trims email before calling repository', () async {
      when(
        repository.linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'secret1',
        ),
      ).thenAnswer((_) async => profile);

      await useCase(email: '  ana@example.com  ', password: 'secret1');

      verify(
        repository.linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'secret1',
        ),
      ).called(1);
    });

    test('throws ValidationFailure when email is invalid', () async {
      expect(
        () => useCase(email: 'not-an-email', password: 'secret1'),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(
        repository.linkGoogleAccountWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });

    test('throws ValidationFailure when password is empty', () async {
      expect(
        () => useCase(email: 'ana@example.com', password: ''),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(
        repository.linkGoogleAccountWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      );
    });
  });
}
