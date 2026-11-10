import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_result_image_renderer.dart';
import 'package:la_pocha/features/share_result/domain/usecases/build_share_result_caption_usecase.dart';
import 'package:la_pocha/features/share_result/domain/usecases/share_game_result_usecase.dart';
import 'package:la_pocha/features/share_result/presentation/bloc/share_result_cubit.dart';
import 'package:la_pocha/features/share_result/presentation/widgets/share_result_button.dart';
import 'package:mocktail/mocktail.dart';

class MockShareResultImageRenderer extends Mock
    implements ShareResultImageRenderer {}

class MockShareGameResultUseCase extends Mock
    implements ShareGameResultUseCase {}

void main() {
  late MockShareResultImageRenderer imageRenderer;
  late MockShareGameResultUseCase shareGameResult;

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
  });

  setUp(() {
    imageRenderer = MockShareResultImageRenderer();
    shareGameResult = MockShareGameResultUseCase();
    when(
      () => imageRenderer.renderPngFile(any()),
    ).thenAnswer((_) async => '/tmp/la_pocha_share_result.png');
    when(
      () => shareGameResult(
        imageFilePath: any(named: 'imageFilePath'),
        caption: any(named: 'caption'),
        origin: any(named: 'origin'),
      ),
    ).thenAnswer((_) async => ShareOutcome.unavailable);
  });

  ShareResultCubit buildCubit() => ShareResultCubit(
    buildCaption: const BuildShareResultCaptionUseCase(),
    imageRenderer: imageRenderer,
    shareGameResult: shareGameResult,
  );

  testWidgets('hides when ranking is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => buildCubit(),
          child: const Scaffold(
            body: ShareResultButton(
              payload: ShareResultPayload(
                ranking: [],
                finishedAt: null,
                playerCount: 0,
                roundCount: 0,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.ios_share), findsNothing);
  });

  testWidgets('shows share icon when ranking is not empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => buildCubit(),
          child: Scaffold(body: ShareResultButton(payload: payload)),
        ),
      ),
    );

    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    expect(find.byTooltip('Compartir'), findsOneWidget);
  });
}
