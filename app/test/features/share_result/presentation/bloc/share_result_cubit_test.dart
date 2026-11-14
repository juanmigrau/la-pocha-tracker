import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_result_image_renderer.dart';
import 'package:la_pocha/features/share_result/domain/usecases/build_share_result_caption_usecase.dart';
import 'package:la_pocha/features/share_result/domain/usecases/share_game_result_usecase.dart';
import 'package:la_pocha/features/share_result/presentation/bloc/share_result_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildShareResultCaptionUseCase extends Mock
    implements BuildShareResultCaptionUseCase {}

class MockShareResultImageRenderer extends Mock
    implements ShareResultImageRenderer {}

class MockShareGameResultUseCase extends Mock
    implements ShareGameResultUseCase {}

void main() {
  late MockBuildShareResultCaptionUseCase buildCaption;
  late MockShareResultImageRenderer imageRenderer;
  late MockShareGameResultUseCase shareGameResult;

  const origin = ShareOrigin(x: 1, y: 2, width: 3, height: 4);

  final payload = ShareResultPayload(
    ranking: [
      RankingEntry(
        player: PlayerEmbed(
          id: '1',
          displayName: 'María',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 245,
          joinedAt: DateTime(2026, 1, 1),
        ),
        rank: 1,
        roundScore: 0,
        totalScore: 245,
      ),
    ],
    finishedAt: DateTime(2026, 7, 4),
    playerCount: 1,
    roundCount: 19,
  );

  setUpAll(() {
    registerFallbackValue(payload);
    registerFallbackValue(origin);
  });

  setUp(() {
    buildCaption = MockBuildShareResultCaptionUseCase();
    imageRenderer = MockShareResultImageRenderer();
    shareGameResult = MockShareGameResultUseCase();
  });

  ShareResultCubit buildCubit() => ShareResultCubit(
    buildCaption: buildCaption,
    imageRenderer: imageRenderer,
    shareGameResult: shareGameResult,
  );

  void stubHappyPath({ShareOutcome outcome = ShareOutcome.shared}) {
    when(
      () => buildCaption(any()),
    ).thenReturn('La Pocha: gana María con 245 pts');
    when(
      () => imageRenderer.renderPngFile(any()),
    ).thenAnswer((_) async => '/tmp/la_pocha_share_result.png');
    when(
      () => shareGameResult(
        imageFilePath: any(named: 'imageFilePath'),
        caption: any(named: 'caption'),
        origin: any(named: 'origin'),
      ),
    ).thenAnswer((_) async => outcome);
  }

  blocTest<ShareResultCubit, ShareResultState>(
    'emits InProgress then Success when shared',
    build: buildCubit,
    setUp: stubHappyPath,
    act: (cubit) => cubit.share(payload: payload, origin: origin),
    expect: () => [isA<ShareResultInProgress>(), isA<ShareResultSuccess>()],
  );

  blocTest<ShareResultCubit, ShareResultState>(
    'emits Success when platform reports unavailable',
    build: buildCubit,
    setUp: () => stubHappyPath(outcome: ShareOutcome.unavailable),
    act: (cubit) => cubit.share(payload: payload, origin: origin),
    expect: () => [isA<ShareResultInProgress>(), isA<ShareResultSuccess>()],
  );

  blocTest<ShareResultCubit, ShareResultState>(
    'emits Initial when user dismisses share sheet',
    build: buildCubit,
    setUp: () => stubHappyPath(outcome: ShareOutcome.dismissed),
    act: (cubit) => cubit.share(payload: payload, origin: origin),
    expect: () => [isA<ShareResultInProgress>(), isA<ShareResultInitial>()],
  );

  blocTest<ShareResultCubit, ShareResultState>(
    'emits Failure when renderer throws',
    build: buildCubit,
    setUp: () {
      when(() => buildCaption(any())).thenReturn('caption');
      when(
        () => imageRenderer.renderPngFile(any()),
      ).thenThrow(StateError('render failed'));
    },
    act: (cubit) => cubit.share(payload: payload),
    expect: () => [
      isA<ShareResultInProgress>(),
      isA<ShareResultFailure>().having(
        (state) => state.message,
        'message',
        shareResultFailureMessage,
      ),
    ],
  );

  blocTest<ShareResultCubit, ShareResultState>(
    'emits Failure when share throws',
    build: buildCubit,
    setUp: () {
      when(() => buildCaption(any())).thenReturn('caption');
      when(
        () => imageRenderer.renderPngFile(any()),
      ).thenAnswer((_) async => '/tmp/la_pocha_share_result.png');
      when(
        () => shareGameResult(
          imageFilePath: any(named: 'imageFilePath'),
          caption: any(named: 'caption'),
          origin: any(named: 'origin'),
        ),
      ).thenThrow(Exception('share failed'));
    },
    act: (cubit) => cubit.share(payload: payload, origin: origin),
    expect: () => [
      isA<ShareResultInProgress>(),
      isA<ShareResultFailure>().having(
        (state) => state.message,
        'message',
        shareResultFailureMessage,
      ),
    ],
  );

  blocTest<ShareResultCubit, ShareResultState>(
    'emits Failure when caption rejects empty ranking',
    build: buildCubit,
    setUp: () {
      when(
        () => buildCaption(any()),
      ).thenThrow(ArgumentError('Ranking must not be empty'));
    },
    act: (cubit) => cubit.share(
      payload: const ShareResultPayload(
        ranking: [],
        finishedAt: null,
        playerCount: 0,
        roundCount: 0,
      ),
    ),
    expect: () => [isA<ShareResultInProgress>(), isA<ShareResultFailure>()],
  );
}
