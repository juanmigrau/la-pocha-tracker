import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/create_game_draft_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/value_objects/game_deck_config.dart';

part 'create_game_event.dart';
part 'create_game_state.dart';

class CreateGameBloc extends Bloc<CreateGameEvent, CreateGameState> {
  CreateGameBloc({required this._createGameDraft})
      : super(previewFor(defaultPlayerCount)) {
    on<PlayerCountChanged>(_onPlayerCountChanged);
    on<CreateGameConfirmed>(_onCreateGameConfirmed);
  }

  /// Default preselected player count for a new game.
  static const int defaultPlayerCount = 4;

  final CreateGameDraftUseCase _createGameDraft;

  static CreateGamePreview previewFor(int playerCount) {
    final config = GameDeckConfig.fromPlayerCount(playerCount);
    return CreateGamePreview(
      playerCount: playerCount,
      totalCards: config.totalCards,
      maxCardsPerRound: config.maxCardsPerRound,
      totalRounds: config.totalRounds,
    );
  }

  void _onPlayerCountChanged(
    PlayerCountChanged event,
    Emitter<CreateGameState> emit,
  ) {
    emit(previewFor(event.playerCount));
  }

  Future<void> _onCreateGameConfirmed(
    CreateGameConfirmed event,
    Emitter<CreateGameState> emit,
  ) async {
    final currentPreview = switch (state) {
      final CreateGamePreview preview => preview,
      final CreateGameSubmitting submitting => CreateGamePreview(
          playerCount: submitting.playerCount,
          totalCards: submitting.totalCards,
          maxCardsPerRound: submitting.maxCardsPerRound,
          totalRounds: submitting.totalRounds,
        ),
      final CreateGameFailure failure => CreateGamePreview(
          playerCount: failure.playerCount,
          totalCards: failure.totalCards,
          maxCardsPerRound: failure.maxCardsPerRound,
          totalRounds: failure.totalRounds,
        ),
      _ => previewFor(defaultPlayerCount),
    };

    emit(CreateGameSubmitting(
      playerCount: currentPreview.playerCount,
      totalCards: currentPreview.totalCards,
      maxCardsPerRound: currentPreview.maxCardsPerRound,
      totalRounds: currentPreview.totalRounds,
    ));

    try {
      final game = await _createGameDraft(playerCount: currentPreview.playerCount);
      emit(CreateGameSuccess(gameId: game.id));
    } catch (error) {
      emit(CreateGameFailure(
        message: mapExceptionToUserMessage(error),
        playerCount: currentPreview.playerCount,
        totalCards: currentPreview.totalCards,
        maxCardsPerRound: currentPreview.maxCardsPerRound,
        totalRounds: currentPreview.totalRounds,
      ));
    }
  }
}
