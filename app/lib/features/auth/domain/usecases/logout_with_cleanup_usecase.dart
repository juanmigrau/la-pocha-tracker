import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';

class LogoutWithCleanupUseCase {
  const LogoutWithCleanupUseCase({
    required this._authRepository,
    required this._gameRepository,
    required this._favoriteRepository,
    required this._localUser,
  });

  final AuthRepository _authRepository;
  final GameRepository _gameRepository;
  final FavoriteRepository _favoriteRepository;
  final LocalUserService _localUser;

  Future<int> countUnsyncedGames() => _gameRepository.countUnsyncedGames();

  Future<void> execute() async {
    await _authRepository.signOut();
    await _gameRepository.clearAllLocalData();
    await _favoriteRepository.clearAll();
    await _localUser.clearAll();
  }
}
