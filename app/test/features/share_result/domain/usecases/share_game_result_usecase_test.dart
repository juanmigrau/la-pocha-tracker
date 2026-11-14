import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_sheet_gateway.dart';
import 'package:la_pocha/features/share_result/domain/usecases/share_game_result_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockShareSheetGateway extends Mock implements ShareSheetGateway {}

void main() {
  late MockShareSheetGateway gateway;
  late ShareGameResultUseCase useCase;

  const origin = ShareOrigin(x: 10, y: 20, width: 40, height: 48);

  setUpAll(() {
    registerFallbackValue(origin);
  });

  setUp(() {
    gateway = MockShareSheetGateway();
    useCase = ShareGameResultUseCase(gateway);
  });

  test('delegates to gateway with origin and returns outcome', () async {
    when(
      () => gateway.shareImage(
        filePath: any(named: 'filePath'),
        caption: any(named: 'caption'),
        origin: any(named: 'origin'),
      ),
    ).thenAnswer((_) async => ShareOutcome.shared);

    final outcome = await useCase(
      imageFilePath: '/tmp/la_pocha_share_result.png',
      caption: 'La Pocha: gana María con 245 pts',
      origin: origin,
    );

    expect(outcome, ShareOutcome.shared);
    verify(
      () => gateway.shareImage(
        filePath: '/tmp/la_pocha_share_result.png',
        caption: 'La Pocha: gana María con 245 pts',
        origin: origin,
      ),
    ).called(1);
  });

  test('propagates gateway exceptions', () async {
    when(
      () => gateway.shareImage(
        filePath: any(named: 'filePath'),
        caption: any(named: 'caption'),
        origin: any(named: 'origin'),
      ),
    ).thenThrow(Exception('share failed'));

    await expectLater(
      () => useCase(
        imageFilePath: '/tmp/la_pocha_share_result.png',
        caption: 'La Pocha: gana María con 245 pts',
        origin: origin,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects empty image path', () async {
    await expectLater(
      () => useCase(
        imageFilePath: '  ',
        caption: 'La Pocha: gana María con 245 pts',
      ),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(
      () => gateway.shareImage(
        filePath: any(named: 'filePath'),
        caption: any(named: 'caption'),
        origin: any(named: 'origin'),
      ),
    );
  });

  test('rejects empty caption', () async {
    await expectLater(
      () =>
          useCase(imageFilePath: '/tmp/la_pocha_share_result.png', caption: ''),
      throwsA(isA<ArgumentError>()),
    );
  });
}
