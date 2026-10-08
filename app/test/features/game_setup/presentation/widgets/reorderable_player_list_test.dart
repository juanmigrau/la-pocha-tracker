import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/dealer_selector.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/reorderable_player_list.dart';

void main() {
  PlayerEmbed player({
    required String id,
    required String displayName,
    required int seatOrder,
  }) {
    return PlayerEmbed(
      id: id,
      displayName: displayName,
      isGuest: true,
      userId: null,
      seatOrder: seatOrder,
      totalScore: 0,
      joinedAt: DateTime(2026),
    );
  }

  final players = [
    player(id: 'p1', displayName: 'Ana', seatOrder: 1),
    player(id: 'p2', displayName: 'Luis', seatOrder: 2),
    player(id: 'p3', displayName: 'María', seatOrder: 3),
  ];

  Future<void> pumpList(
    WidgetTester tester, {
    required String firstDealerPlayerId,
    String? highlightedPlayerId,
    double winnerScale = 1.0,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReorderablePlayerList(
            players: players,
            firstDealerPlayerId: firstDealerPlayerId,
            highlightedPlayerId: highlightedPlayerId,
            winnerScale: winnerScale,
            onReorder: (_, _) {},
            onDealerSelected: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('marks selected dealer with filled style icon', (tester) async {
    await pumpList(tester, firstDealerPlayerId: 'p2');

    final selectors = tester
        .widgetList<DealerSelector>(find.byType(DealerSelector))
        .toList();
    expect(selectors, hasLength(3));
    expect(selectors[0].isSelected, isFalse);
    expect(selectors[1].isSelected, isTrue);
    expect(selectors[2].isSelected, isFalse);
    expect(find.byIcon(Icons.style), findsOneWidget);
    expect(find.byIcon(Icons.style_outlined), findsNWidgets(2));
  });

  testWidgets('applies highlight decoration to highlighted player row', (
    tester,
  ) async {
    await pumpList(
      tester,
      firstDealerPlayerId: 'p1',
      highlightedPlayerId: 'p3',
    );

    final highlighted = tester.widget<AnimatedContainer>(
      find.byKey(const Key('playerRow_p3')),
    );
    final decoration = highlighted.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect((decoration.border! as Border).top.color, AppTheme.primary);

    final notHighlighted = tester.widget<AnimatedContainer>(
      find.byKey(const Key('playerRow_p1')),
    );
    final plain = notHighlighted.decoration! as BoxDecoration;
    expect((plain.border! as Border).top.color, Colors.transparent);
  });
}
