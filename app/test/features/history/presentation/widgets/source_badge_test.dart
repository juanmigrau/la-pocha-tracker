import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/presentation/widgets/source_badge.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows Local for local source without syncStatus', (tester) async {
    await tester.pumpWidget(
      wrap(const SourceBadge(source: GameHistorySource.local)),
    );

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Nube'), findsNothing);
  });

  testWidgets('shows Nube when syncStatus is synced even if source is local', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SourceBadge(
          source: GameHistorySource.local,
          syncStatus: SyncStatus.synced,
        ),
      ),
    );

    expect(find.text('Nube'), findsOneWidget);
    expect(find.text('Local'), findsNothing);
  });

  testWidgets('shows Pendiente when syncStatus is pending', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SourceBadge(
          source: GameHistorySource.local,
          syncStatus: SyncStatus.pending,
        ),
      ),
    );

    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('shows Error sync when syncStatus is failed', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SourceBadge(
          source: GameHistorySource.local,
          syncStatus: SyncStatus.failed,
        ),
      ),
    );

    expect(find.text('Error sync'), findsOneWidget);
  });
}
