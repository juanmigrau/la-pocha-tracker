import 'package:la_pocha/core/config/debug_config_notifier.dart';
import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/services/round_sequence_builder.dart';
import 'package:la_pocha/features/game_setup/domain/value_objects/game_deck_config.dart';
import 'package:uuid/uuid.dart';

class CreateGameDraftUseCase {
  CreateGameDraftUseCase(
    this._repository,
    this._localUser, {
    Uuid? uuid,
    this.debugConfig,
  }) : _uuid = uuid ?? const Uuid();

  final GameRepository _repository;
  final LocalUserService _localUser;
  final Uuid _uuid;
  final DebugConfigNotifier? debugConfig;

  Future<Game> call({required int playerCount}) async {
    if (playerCount < 3 || playerCount > 8) {
      throw ArgumentError.value(
        playerCount,
        'playerCount',
        'Must be between 3 and 8',
      );
    }

    final config = GameDeckConfig.fromPlayerCount(playerCount);
    final roundSequence = buildRoundSequence(
      maxCardsPerRound: config.maxCardsPerRound,
      playerCount: playerCount,
      debugConfig: debugConfig,
    );
    final now = DateTime.now();
    final localId = await _localUser.getOrCreateLocalId();
    final name = _localUser.getLocalName()?.trim();
    final organizer = PlayerEmbed(
      id: _uuid.v4(),
      displayName: (name == null || name.isEmpty) ? 'Jugador' : name,
      isGuest: true,
      userId: null,
      localUserId: localId,
      seatOrder: 0,
      totalScore: 0,
      joinedAt: now,
    );

    final game = Game(
      id: _uuid.v4(),
      status: GameStatus.setup,
      playerCount: playerCount,
      totalCards: config.totalCards,
      maxCardsPerRound: config.maxCardsPerRound,
      roundSequence: roundSequence,
      players: [organizer],
      createdAt: now,
      updatedAt: now,
    );

    return _repository.saveDraft(game);
  }
}
