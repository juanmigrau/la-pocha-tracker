import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/usecases/get_recent_games_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getRecentGames,
    Stream<AuthState>? authStateChanges,
    AuthState? initialAuthState,
  }) : _previousAuthState = initialAuthState,
       super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<_HomeWatchData>(_onWatchData);
    on<_HomeWatchFailed>(_onWatchFailed);

    if (authStateChanges != null) {
      _authSubscription = authStateChanges.listen(_onAuthStateChanged);
    }
  }

  final GetRecentGamesUseCase _getRecentGames;
  StreamSubscription<List<GameHistoryItem>>? _subscription;
  StreamSubscription<AuthState>? _authSubscription;
  AuthState? _previousAuthState;

  /// Reloads local Drift history when the user signs out.
  /// [GetRecentGamesUseCase] already watches Drift only (no Firestore).
  void _onAuthStateChanged(AuthState state) {
    final wasAuthenticated = _previousAuthState is Authenticated;
    _previousAuthState = state;
    if (wasAuthenticated && state is Unauthenticated) {
      add(const HomeStarted());
    }
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    await _subscription?.cancel();
    _subscription = _getRecentGames().listen(
      (games) => add(_HomeWatchData(games)),
      onError: (Object error, StackTrace _) => add(_HomeWatchFailed(error)),
    );
  }

  void _onWatchData(_HomeWatchData event, Emitter<HomeState> emit) {
    if (event.recentGames.isEmpty) {
      emit(const HomeEmpty());
      return;
    }
    emit(HomeLoaded(recentGames: event.recentGames));
  }

  void _onWatchFailed(_HomeWatchFailed event, Emitter<HomeState> emit) {
    emit(HomeFailure(message: mapExceptionToUserMessage(event.error)));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _authSubscription?.cancel();
    return super.close();
  }
}
