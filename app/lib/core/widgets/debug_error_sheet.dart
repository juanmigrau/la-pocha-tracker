import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that surfaces full exception details for developers.
///
/// Only shown when [kDebugMode] is true. Release builds must never call this
/// for user-facing UX; use [showIfDebug] which is a safe no-op in release.
class DebugErrorSheet extends StatelessWidget {
  const DebugErrorSheet({
    super.key,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  /// Shows the debug sheet when running in debug mode; no-op in release.
  static Future<void> showIfDebug(
    BuildContext context, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) {
      return Future<void>.value();
    }
    return show(context, error: error, stackTrace: stackTrace);
  }

  /// Shows the debug error bottom sheet. Prefer [showIfDebug] from call sites.
  static Future<void> show(
    BuildContext context, {
    required Object error,
    StackTrace? stackTrace,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DebugErrorSheet(error: error, stackTrace: stackTrace);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stackText = stackTrace?.toString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debug — Error detalle',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            SelectableText(
              error.runtimeType.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Message',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.25,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            if (stackText != null && stackText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Stack trace',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    stackText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
