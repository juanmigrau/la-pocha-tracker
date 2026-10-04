import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/logout_with_cleanup_usecase.dart';
import 'package:la_pocha/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'logout_with_cleanup_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<GameRepository>(),
  MockSpec<FavoriteRepository>(),
  MockSpec<LocalUserService>(),
])
void main() {
  late MockAuthRepository authRepository;
  late MockGameRepository gameRepository;
  late MockFavoriteRepository favoriteRepository;
  late MockLocalUserService localUser;
  late LogoutWithCleanupUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    gameRepository = MockGameRepository();
    favoriteRepository = MockFavoriteRepository();
    localUser = MockLocalUserService();
    useCase = LogoutWithCleanupUseCase(
      authRepository: authRepository,
      gameRepository: gameRepository,
      favoriteRepository: favoriteRepository,
      localUser: localUser,
    );
  });

  test('countUnsyncedGames delegates to game repository', () async {
    when(gameRepository.countUnsyncedGames()).thenAnswer((_) async => 3);

    expect(await useCase.countUnsyncedGames(), 3);
  });

  test('execute signs out and clears local data', () async {
    when(authRepository.signOut()).thenAnswer((_) async {});
    when(gameRepository.clearAllLocalData()).thenAnswer((_) async {});
    when(favoriteRepository.clearAll()).thenAnswer((_) async {});
    when(localUser.clearAll()).thenAnswer((_) async {});

    await useCase.execute();

    verifyInOrder([
      authRepository.signOut(),
      gameRepository.clearAllLocalData(),
      favoriteRepository.clearAll(),
      localUser.clearAll(),
    ]);
  });
}
