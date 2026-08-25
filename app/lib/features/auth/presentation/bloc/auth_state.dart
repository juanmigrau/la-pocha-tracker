part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class PasswordResetEmailSent extends AuthState {
  const PasswordResetEmailSent();
}

final class AuthNeedsPasswordToLink extends AuthState {
  const AuthNeedsPasswordToLink({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthGoogleAccountExists extends AuthState {
  const AuthGoogleAccountExists();
}
