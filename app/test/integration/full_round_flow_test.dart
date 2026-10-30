@Tags(['integration'])
library;

/*
 * Test de integración del flujo completo de una partida de 3 jugadores.
 *
 * Verifica las fases: creación → configuración de mesa → apuestas (con
 * validación de la restricción del repartidor) → bazas → puntuación →
 * avance de ronda → finalización sin cuenta.
 *
 * Dependencias: Drift real con AppDatabase.forTesting(), use cases reales,
 * sin mocks y sin Firebase.
 *
 * Queda excluida la sincronización a Firestore (requiere sesión autenticada);
 * ese escenario se cubre en game_sync_firestore_test.dart.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/database/app_database.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/game_setup/data/datasources/game_local_datasource.dart';
import 'package:la_pocha/features/game_setup/data/datasources/round_local_datasource.dart';
import 'package:la_pocha/features/game_setup/data/repositories/game_repository_impl.dart';
import 'package:la_pocha/features/game_setup/data/repositories/round_repository_impl.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/game_setup/domain/services/dealer_rotation_service.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/add_player_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/create_game_draft_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/set_first_dealer_usecase.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/start_game_usecase.dart';
import 'package:la_pocha/features/history/data/datasources/history_local_datasource.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/round/domain/services/bid_order_service.dart';
import 'package:la_pocha/features/round/domain/usecases/advance_to_next_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/close_bidding_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/close_round_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/submit_bid_usecase.dart';
import 'package:la_pocha/features/round/domain/usecases/submit_tricks_usecase.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';
import 'package:la_pocha/features/sync/domain/repositories/game_sync_repository.dart';
import 'package:la_pocha/features/sync/domain/usecases/upload_finished_game_usecase.dart';

/// Guest / unauthenticated session for local-only play.
///
/// [AuthRepositoryImpl] requires Firebase; this double only models "no session"
/// so [UploadFinishedGameUseCase] can exercise the real skip path without
/// initializing Firebase (unlike [game_sync_firestore_test.dart]).
class _NoSessionAuthRepository implements AuthRepository {
  @override
  Stream<UserProfile?> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserProfile?> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserProfile> linkGoogleAccountWithPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> linkLocalId({
    required String firebaseUid,
    required String localId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<UserProfile> updateDisplayName(String displayName) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount({String? password}) => throw UnimplementedError();
}

/// Fails if upload is attempted — proves the no-session path never reaches sync.
class _MustNotUploadGameSyncRepository implements GameSyncRepository {
  @override
  Future<GameUploadResult> uploadFinishedGame({
    required String gameId,
    required String hostId,
  }) {
    fail(
      'uploadFinishedGame must not be called without an authenticated session',
    );
  }

  @override
  Future<List<Game>> getPendingGames() async => const [];
}

void main() {
  late AppDatabase database;
  late GameLocalDatasource gameLocalDatasource;
  late RoundLocalDatasource roundLocalDatasource;
  late GameRepository gameRepository;
  late RoundRepository roundRepository;
  late HistoryLocalDatasource historyLocalDatasource;

  late CreateGameDraftUseCase createGameDraft;
  late AddPlayerUseCase addPlayer;
  late SetFirstDealerUseCase setFirstDealer;
  late StartGameUseCase startGame;
  late SubmitBidUseCase submitBid;
  late CloseBiddingUseCase closeBidding;
  late CloseRoundUseCase closeRound;
  late AdvanceToNextRoundUseCase advanceToNextRound;
  late UploadFinishedGameUseCase uploadFinishedGame;

  const bidOrder = BidOrderService();

  setUp(() {
    database = AppDatabase.forTesting();
    gameLocalDatasource = GameLocalDatasource(database);
    roundLocalDatasource = RoundLocalDatasource(database);
    gameRepository = GameRepositoryImpl(gameLocalDatasource);
    roundRepository = RoundRepositoryImpl(roundLocalDatasource);
    historyLocalDatasource = HistoryLocalDatasource(
      database,
      gameLocalDatasource,
      roundLocalDatasource,
    );

    createGameDraft = CreateGameDraftUseCase(gameRepository);
    addPlayer = AddPlayerUseCase(gameRepository);
    setFirstDealer = const SetFirstDealerUseCase();
    startGame = StartGameUseCase(gameRepository);
    submitBid = SubmitBidUseCase(roundRepository);
    closeBidding = CloseBiddingUseCase(roundRepository);
    closeRound = CloseRoundUseCase(gameRepository, SubmitTricksUseCase());
    advanceToNextRound = AdvanceToNextRoundUseCase(
      gameRepository,
      const DealerRotationService(),
    );
    uploadFinishedGame = UploadFinishedGameUseCase(
      authRepository: _NoSessionAuthRepository(),
      gameSyncRepository: _MustNotUploadGameSyncRepository(),
      gameLocalDatasource: gameLocalDatasource,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'full round flow: setup → bidding → tricks → advance → local finish without Firestore',
    () async {
      // --- 1. Create game with 3 free-name (guest) players ---
      var game = await createGameDraft(playerCount: 3);
      expect(game.status, GameStatus.setup);
      expect(game.roundSequence, hasLength(21));

      game = await addPlayer(gameId: game.id, name: 'Ana');
      game = await addPlayer(gameId: game.id, name: 'Bob');
      game = await addPlayer(gameId: game.id, name: 'Carla');

      final storedSetup = await gameRepository.getGameById(game.id);
      expect(storedSetup, isNotNull);
      expect(storedSetup!.status, GameStatus.setup);
      expect(storedSetup.roundSequence, hasLength(21));
      expect(storedSetup.players, hasLength(3));

      // --- 2. Table order + first dealer (dealer = Carla / player 3) ---
      // AddPlayer assigns 0-based seatOrder; GameSetupBloc normalizes to 1-based
      // before start. Persist the same seat order the UI would pass to StartGame.
      final seatedPlayers = [
        for (var i = 0; i < game.players.length; i++)
          game.players[i].copyWith(seatOrder: i + 1),
      ];
      game = await gameRepository.updateGamePlayers(game.id, seatedPlayers);

      final firstDealerPlayerId = setFirstDealer(
        players: game.players,
        playerId: game.players[2].id, // Carla
      );

      expect(
        game.players.map((player) => player.seatOrder).toList(),
        [1, 2, 3],
      );
      expect(firstDealerPlayerId, game.players[2].id);
      // firstDealerPlayerId is persisted by StartGameUseCase / startGame below.

      final player1 = game.players[0]; // Ana, seat 1
      final player2 = game.players[1]; // Bob, seat 2
      final player3 = game.players[2]; // Carla, seat 3 (first dealer)

      // --- 3. Start game → in_progress, round 1 with 1 card ---
      final startResult = await startGame(
        game: game,
        players: game.players,
        firstDealerPlayerId: firstDealerPlayerId,
      );

      game = (await gameRepository.getGameById(game.id))!;
      expect(game.status, GameStatus.inProgress);
      expect(game.firstDealerPlayerId, player3.id);
      expect(game.currentRoundNumber, 1);

      var round = await roundRepository.getRoundByGameAndNumber(game.id, 1);
      expect(round, isNotNull);
      expect(round!.id, startResult.roundId);
      expect(round.status, RoundStatus.bidding);
      expect(round.cardsInRound, 1);
      expect(round.dealerPlayerId, player3.id);

      // --- 4. Bidding phase (1 card): 0, 0, dealer cannot bid 1, then 0 ---
      final biddingOrder = bidOrder.biddingOrder(
        players: game.players,
        dealerPlayerId: round.dealerPlayerId,
      );
      // Left of dealer first: Ana → Bob → Carla (dealer last)
      expect(biddingOrder, [player1.id, player2.id, player3.id]);

      var bidResult = await submitBid(
        round: round,
        biddingOrder: biddingOrder,
        currentPlayerId: player1.id,
        bid: 0,
      );
      round = bidResult.round;

      bidResult = await submitBid(
        round: round,
        biddingOrder: biddingOrder,
        currentPlayerId: player2.id,
        bid: 0,
      );
      round = bidResult.round;

      // Forbidden dealer bid = 1 when others bid 0+0 on a 1-card round.
      await expectLater(
        submitBid(
          round: round,
          biddingOrder: biddingOrder,
          currentPlayerId: player3.id,
          bid: 1,
        ),
        throwsA(isA<StateError>()),
      );

      bidResult = await submitBid(
        round: round,
        biddingOrder: biddingOrder,
        currentPlayerId: player3.id,
        bid: 0,
      );
      round = bidResult.round;

      round = await closeBidding(
        round: round,
        playerIds: game.players.map((player) => player.id).toList(),
      );
      expect(round.status, RoundStatus.playing);
      expect(round.bids, {
        player1.id: 0,
        player2.id: 0,
        player3.id: 0,
      });

      // --- 5. Tricks: Ana wins 1, Bob/Carla win 0 → scores -5 / +10 / +10 ---
      final tricks = {
        player1.id: 1,
        player2.id: 0,
        player3.id: 0,
      };

      round = await closeRound(
        gameId: game.id,
        round: round,
        players: game.players,
        tricks: tricks,
      );

      expect(round.status, RoundStatus.closed);
      expect(round.scoresDelta, {
        player1.id: -5,
        player2.id: 10,
        player3.id: 10,
      });

      game = (await gameRepository.getGameById(game.id))!;
      expect(
        {
          for (final player in game.players) player.id: player.totalScore,
        },
        {
          player1.id: -5,
          player2.id: 10,
          player3.id: 10,
        },
      );

      // --- 6. Advance to round 2 (dealer rotates: Carla → Ana) ---
      // Rotation: next after current dealer by seatOrder. If dealer were player 1,
      // next would be player 2; here dealer was player 3 → next is player 1.
      final round2 = await advanceToNextRound(
        gameId: game.id,
        closedRound: round,
      );

      game = (await gameRepository.getGameById(game.id))!;
      expect(game.currentRoundNumber, 2);
      expect(round2.roundNumber, 2);
      expect(round2.cardsInRound, 2);
      expect(round2.dealerPlayerId, player1.id);
      expect(round2.status, RoundStatus.bidding);

      // --- 7. Finish early via repository helper (skip remaining 19 rounds) ---
      // FinishGameUseCase requires the last closed round of the sequence; for a
      // 21-round game that would be too heavy here. gameRepository.finishGame is
      // the persistence path FinishGameUseCase ultimately calls.
      final finished = await gameRepository.finishGame(
        gameId: game.id,
        finishedAt: DateTime.now(),
      );

      expect(finished.status, GameStatus.finished);
      expect(finished.cloudGameId, isNull);
      expect(finished.syncStatus, SyncStatus.pending);

      final uploadOutcome = await uploadFinishedGame(gameId: game.id);
      expect(uploadOutcome, UploadFinishedGameOutcome.skippedNoSession);

      final afterUpload = await gameRepository.getGameById(game.id);
      expect(afterUpload?.cloudGameId, isNull);
      expect(afterUpload?.syncStatus, isNot(SyncStatus.synced));

      final history = await historyLocalDatasource.getFinishedGames();
      expect(history, hasLength(1));
      expect(history.first.id, game.id);
      expect(history.first.source, GameHistorySource.local);
      expect(history.first.playerCount, 3);
    },
  );
}
