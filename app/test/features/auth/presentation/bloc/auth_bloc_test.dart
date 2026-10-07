import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/failures/auth_failure.dart'
    as domain;
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/link_google_account_with_password_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/link_local_to_firebase_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/logout_with_cleanup_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:la_pocha/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<SignInUseCase>(),
  MockSpec<SignUpUseCase>(),
  MockSpec<SignInWithGoogleUseCase>(),
  MockSpec<LinkGoogleAccountWithPasswordUseCase>(),
  MockSpec<LogoutWithCleanupUseCase>(),
  MockSpec<LinkLocalToFirebaseUseCase>(),
  MockSpec<SendPasswordResetUseCase>(),
])
void main() {
  late MockAuthRepository authRepository;
  late MockSignInUseCase signIn;
  late MockSignUpUseCase signUp;
  late MockSignInWithGoogleUseCase signInWithGoogle;
  late MockLinkGoogleAccountWithPasswordUseCase linkGoogleAccountWithPassword;
  late MockLogoutWithCleanupUseCase logoutWithCleanup;
  late MockLinkLocalToFirebaseUseCase linkLocalToFirebase;
  late MockSendPasswordResetUseCase sendPasswordReset;

  final profile = UserProfile(
    uid: 'uid-1',
    displayName: 'Ana',
    email: 'ana@example.com',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final googleProfile = UserProfile(
    uid: 'uid-google',
    displayName: 'Ana Google',
    email: 'ana@gmail.com',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  AuthBloc buildBloc() => AuthBloc(
        authRepository: authRepository,
        signIn: signIn,
        signUp: signUp,
        signInWithGoogle: signInWithGoogle,
        linkGoogleAccountWithPassword: linkGoogleAccountWithPassword,
        logoutWithCleanup: logoutWithCleanup,
        linkLocalToFirebase: linkLocalToFirebase,
        sendPasswordReset: sendPasswordReset,
      );

  setUp(() {
    authRepository = MockAuthRepository();
    signIn = MockSignInUseCase();
    signUp = MockSignUpUseCase();
    signInWithGoogle = MockSignInWithGoogleUseCase();
    linkGoogleAccountWithPassword = MockLinkGoogleAccountWithPasswordUseCase();
    logoutWithCleanup = MockLogoutWithCleanupUseCase();
    linkLocalToFirebase = MockLinkLocalToFirebaseUseCase();
    sendPasswordReset = MockSendPasswordResetUseCase();
    when(authRepository.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(linkLocalToFirebase.execute(any)).thenAnswer((_) async {});
    when(logoutWithCleanup.execute()).thenAnswer((_) async {});
  });

  blocTest<AuthBloc, AuthState>(
    'emits Authenticated when sign in succeeds and links local id',
    build: buildBloc,
    setUp: () {
      when(signIn(email: 'ana@example.com', password: 'secret1'))
          .thenAnswer((_) async => profile);
    },
    act: (bloc) => bloc.add(
      const SignInSubmitted(
        email: 'ana@example.com',
        password: 'secret1',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      Authenticated(profile),
    ],
    verify: (_) {
      verify(linkLocalToFirebase.execute('uid-1')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure then Unauthenticated when sign in fails',
    build: buildBloc,
    setUp: () {
      when(signIn(email: 'ana@example.com', password: 'bad'))
          .thenThrow(const domain.InvalidCredentialsFailure());
    },
    act: (bloc) => bloc.add(
      const SignInSubmitted(
        email: 'ana@example.com',
        password: 'bad',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthFailure(
        message: 'Contraseña incorrecta',
        error: domain.InvalidCredentialsFailure(),
      ),
      const Unauthenticated(),
    ],
    verify: (_) {
      verifyNever(linkLocalToFirebase.execute(any));
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits Authenticated when sign up succeeds',
    build: buildBloc,
    setUp: () {
      when(
        signUp(
          email: 'ana@example.com',
          password: 'secret1',
          displayName: 'Ana',
        ),
      ).thenAnswer((_) async => profile);
    },
    act: (bloc) => bloc.add(
      const SignUpSubmitted(
        displayName: 'Ana',
        email: 'ana@example.com',
        password: 'secret1',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      Authenticated(profile),
    ],
    verify: (_) {
      verify(linkLocalToFirebase.execute('uid-1')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthGoogleAccountExists then Unauthenticated when Google account exists',
    build: buildBloc,
    setUp: () {
      when(
        signUp(
          email: 'ana@gmail.com',
          password: 'secret1',
          displayName: 'Ana',
        ),
      ).thenThrow(const domain.GoogleAccountAlreadyExistsFailure());
    },
    act: (bloc) => bloc.add(
      const SignUpSubmitted(
        displayName: 'Ana',
        email: 'ana@gmail.com',
        password: 'secret1',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthGoogleAccountExists(),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits Authenticated when Google sign in succeeds',
    build: buildBloc,
    setUp: () {
      when(signInWithGoogle()).thenAnswer((_) async => googleProfile);
    },
    act: (bloc) => bloc.add(const GoogleSignInSubmitted()),
    expect: () => [
      const AuthLoading(),
      Authenticated(googleProfile),
    ],
    verify: (_) {
      verify(linkLocalToFirebase.execute('uid-google')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits Unauthenticated without failure when Google sign in is cancelled',
    build: buildBloc,
    setUp: () {
      when(signInWithGoogle()).thenAnswer((_) async => null);
    },
    act: (bloc) => bloc.add(const GoogleSignInSubmitted()),
    expect: () => [
      const AuthLoading(),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure then Unauthenticated when Google sign in fails',
    build: buildBloc,
    setUp: () {
      when(signInWithGoogle()).thenThrow(const domain.NetworkUnavailableFailure());
    },
    act: (bloc) => bloc.add(const GoogleSignInSubmitted()),
    expect: () => [
      const AuthLoading(),
      const AuthFailure(
        message: 'Sin conexión a internet',
        error: domain.NetworkUnavailableFailure(),
      ),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthNeedsPasswordToLink when Google account conflicts with password',
    build: buildBloc,
    setUp: () {
      when(signInWithGoogle()).thenThrow(
        const domain.AccountExistsWithDifferentCredentialFailure(
          email: 'ana@example.com',
        ),
      );
    },
    act: (bloc) => bloc.add(const GoogleSignInSubmitted()),
    expect: () => [
      const AuthLoading(),
      const AuthNeedsPasswordToLink(email: 'ana@example.com'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits Authenticated when linking Google account with password succeeds',
    build: buildBloc,
    setUp: () {
      when(
        linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'secret1',
        ),
      ).thenAnswer((_) async => profile);
    },
    act: (bloc) => bloc.add(
      const LinkAccountWithPasswordRequested(
        email: 'ana@example.com',
        password: 'secret1',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      Authenticated(profile),
    ],
    verify: (_) {
      verify(linkLocalToFirebase.execute('uid-1')).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure then Unauthenticated when linking Google account fails',
    build: buildBloc,
    setUp: () {
      when(
        linkGoogleAccountWithPassword(
          email: 'ana@example.com',
          password: 'bad',
        ),
      ).thenThrow(const domain.InvalidCredentialsFailure());
    },
    act: (bloc) => bloc.add(
      const LinkAccountWithPasswordRequested(
        email: 'ana@example.com',
        password: 'bad',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthFailure(
        message: 'Contraseña incorrecta',
        error: domain.InvalidCredentialsFailure(),
      ),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits Unauthenticated when logout with cleanup succeeds',
    build: buildBloc,
    seed: () => Authenticated(profile),
    act: (bloc) => bloc.add(const SignOutRequested()),
    expect: () => [
      const AuthLoading(),
      const Unauthenticated(),
    ],
    verify: (_) {
      verify(logoutWithCleanup.execute()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits Authenticated from auth state changes',
    build: buildBloc,
    setUp: () {
      when(authRepository.authStateChanges).thenAnswer(
        (_) => Stream.value(profile),
      );
    },
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [
      Authenticated(profile),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits PasswordResetEmailSent then Unauthenticated when reset succeeds',
    build: buildBloc,
    setUp: () {
      when(sendPasswordReset(email: 'ana@example.com'))
          .thenAnswer((_) async {});
    },
    act: (bloc) => bloc.add(
      const PasswordResetRequested(email: 'ana@example.com'),
    ),
    expect: () => [
      const PasswordResetEmailSent(),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure then Unauthenticated when reset fails',
    build: buildBloc,
    setUp: () {
      when(sendPasswordReset(email: 'missing@example.com'))
          .thenThrow(const domain.UserNotFoundFailure());
    },
    act: (bloc) => bloc.add(
      const PasswordResetRequested(email: 'missing@example.com'),
    ),
    expect: () => [
      const AuthFailure(
        message: 'Usuario no encontrado',
        error: domain.UserNotFoundFailure(),
      ),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits AuthFailure with descriptive message for unexpected errors',
    build: buildBloc,
    setUp: () {
      when(signIn(email: 'ana@example.com', password: 'secret1'))
          .thenThrow(Exception('firestore unavailable'));
    },
    act: (bloc) => bloc.add(
      const SignInSubmitted(
        email: 'ana@example.com',
        password: 'secret1',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      isA<AuthFailure>()
          .having((s) => s.message, 'message', 'Ha ocurrido un error inesperado')
          .having((s) => s.error, 'error', isA<Exception>()),
      const Unauthenticated(),
    ],
  );
}
