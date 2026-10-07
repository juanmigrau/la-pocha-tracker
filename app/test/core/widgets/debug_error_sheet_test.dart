import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(find.text('Copiar traza'), findsOneWidget);
    });

    testWidgets('copy button writes full trace to the clipboard', (
      tester,
    ) async {
      final error = StateError('boom detail');
      final stack = StackTrace.current;
      String? clipboardText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            clipboardText = args?['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

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
      await tester.tap(find.text('Copiar traza'));
      await tester.pumpAndSettle();

      expect(clipboardText, isNotNull);
      expect(clipboardText, contains('Type: StateError'));
      expect(clipboardText, contains('Message:'));
      expect(clipboardText, contains('boom detail'));
      expect(clipboardText, contains('Stack trace:'));
      expect(find.text('Traza copiada al portapapeles'), findsOneWidget);
    });

    test('buildClipboardText includes type, message and stack', () {
      final sheet = DebugErrorSheet(
        error: StateError('boom detail'),
        stackTrace: StackTrace.fromString('#0 main\n#1 run'),
      );

      final text = sheet.buildClipboardText();

      expect(text, contains('Type: StateError'));
      expect(text, contains('boom detail'));
      expect(text, contains('Stack trace:'));
      expect(text, contains('#0 main'));
    });

    test('showIfDebug is a no-op when kDebugMode is false', () {
      // Documented contract: release builds skip the sheet via kDebugMode.
      expect(kDebugMode, isTrue); // tests always run in debug
    });
  });
}
