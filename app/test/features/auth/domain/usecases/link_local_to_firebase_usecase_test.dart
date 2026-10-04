import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:la_pocha/features/auth/domain/repositories/auth_repository.dart';
import 'package:la_pocha/features/auth/domain/usecases/link_local_to_firebase_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'link_local_to_firebase_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<LocalUserService>(),
])
void main() {
  late MockAuthRepository authRepository;
  late MockLocalUserService localUser;
  late LinkLocalToFirebaseUseCase useCase;

  setUp(() {
    authRepository = MockAuthRepository();
    localUser = MockLocalUserService();
    useCase = LinkLocalToFirebaseUseCase(
      localUser: localUser,
      authRepository: authRepository,
    );
  });

  test('links local id to firebase uid via repository', () async {
    when(localUser.getOrCreateLocalId()).thenAnswer((_) async => 'local-1');
    when(
      authRepository.linkLocalId(
        firebaseUid: 'uid-1',
        localId: 'local-1',
      ),
    ).thenAnswer((_) async {});

    await useCase.execute('uid-1');

    verify(localUser.getOrCreateLocalId()).called(1);
    verify(
      authRepository.linkLocalId(
        firebaseUid: 'uid-1',
        localId: 'local-1',
      ),
    ).called(1);
  });
}
