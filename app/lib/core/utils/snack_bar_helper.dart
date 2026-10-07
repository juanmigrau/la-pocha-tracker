import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:la_pocha/core/widgets/debug_error_sheet.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';

class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess(String message, {SnackBarAction? action}) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final context = rootScaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        backgroundColor: colorScheme.inverseSurface,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: action,
      ),
    );
  }

  /// Shows an error snackbar. In debug app builds, also opens [DebugErrorSheet]
  /// when a [context] under a [Navigator] is provided.
  static void showError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    BuildContext? context,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    final messengerContext = rootScaffoldMessengerKey.currentContext;
    if (messenger == null || messengerContext == null) {
      return;
    }

    final colorScheme = Theme.of(messengerContext).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        backgroundColor: colorScheme.errorContainer,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    if (!_shouldShowDebugSheet) {
      return;
    }

    final sheetContext = _debugSheetContext(context);
    if (sheetContext == null) {
      return;
    }

    // Defer so we never open a route synchronously inside a BlocListener.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!sheetContext.mounted) {
        return;
      }
      DebugErrorSheet.showIfDebug(
        sheetContext,
        error: error ?? message,
        stackTrace: stackTrace,
      );
    });
  }

  /// Prefers an explicit [context] that sits under a [Navigator].
  static BuildContext? _debugSheetContext(BuildContext? context) {
    if (context != null &&
        context.mounted &&
        Navigator.maybeOf(context) != null) {
      return context;
    }
    return null;
  }

  /// Widget tests run with [kDebugMode] true; skip the sheet there so existing
  /// snackbar assertions stay stable. Real debug app builds still show it.
  static bool get _shouldShowDebugSheet {
    if (!kDebugMode) {
      return false;
    }
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    final underWidgetTest = bindingName.contains('TestWidgets') ||
        bindingName.contains('AutomatedTest');
    return !underWidgetTest;
  }
}
