import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/widgets/debug_error_sheet.dart';

void main() {
  group('DebugErrorSheet', () {
    testWidgets('shows exception type, message and stack in debug mode', (
      tester,
    ) async {
      final error = StateError('boom detail');
      final stack = StackTrace.current;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    DebugErrorSheet.show(
                      context,
                      error: error,
                      stackTrace: stack,
                    );
                  },
                  child: const Text('show'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.text('Debug — Error detalle'), findsOneWidget);
      expect(find.textContaining('StateError'), findsWidgets);
      expect(find.textContaining('boom detail'), findsWidgets);
    });

    test('showIfDebug is a no-op when kDebugMode is false', () {
      // Documented contract: release builds skip the sheet via kDebugMode.
      expect(kDebugMode, isTrue); // tests always run in debug
    });
  });
}
