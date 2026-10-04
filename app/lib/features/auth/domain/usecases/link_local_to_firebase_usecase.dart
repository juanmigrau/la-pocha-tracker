import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';

class LinkLocalToFirebaseUseCase {
  const LinkLocalToFirebaseUseCase({
    required this._localUser,
    required this._authRepository,
  });

  final LocalUserService _localUser;
  final AuthRepository _authRepository;

  Future<void> execute(String firebaseUid) async {
    final localId = await _localUser.getOrCreateLocalId();
    await _authRepository.linkLocalId(
      firebaseUid: firebaseUid,
      localId: localId,
    );
  }
}
