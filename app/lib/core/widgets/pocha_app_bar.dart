import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PochaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PochaAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.actions,
    this.onBack,
    this.showBackConfirmation = false,
    this.backConfirmationMessage = '¿Seguro que quieres salir?',
    this.leading,
    this.expanded = false,
  }) : assert(
         titleWidget != null || title != '',
         'Provide either title or titleWidget',
       );

  /// Optional icon shown to the left of [title] (e.g. brand fan image).
  final Widget? titleWidget;
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBackConfirmation;
  final String backConfirmationMessage;
  final Widget? leading;
  final bool expanded;

  @override
  Size get preferredSize {
    if (expanded) {
      return const Size.fromHeight(16 + 24 + 56 + 24 + 16);
    }
    return const Size.fromHeight(8 + 16 + 56 + 16);
  }

  Future<void> _handleBack(BuildContext context) async {
    final callback = onBack;
    if (callback == null) {
      return;
    }
    if (!showBackConfirmation) {
      callback();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(backConfirmationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final textTheme = Theme.of(context).textTheme;
    final useBrandTypography = titleWidget != null && title.isNotEmpty;

    final resolvedTitleStyle =
        titleStyle ??
        (useBrandTypography
            ? GoogleFonts.lilitaOne(
                fontSize: expanded ? 28 : 24,
                color: onPrimary,
                height: 1.0,
              )
            : (expanded ? textTheme.headlineSmall : textTheme.titleLarge)
                  ?.copyWith(color: onPrimary, fontWeight: FontWeight.bold));

    final resolvedSubtitleStyle =
        subtitleStyle ??
        (useBrandTypography
            ? GoogleFonts.nunitoSans(
                textStyle: textTheme.bodyMedium,
                color: onPrimary.withValues(alpha: 0.8),
              )
            : textTheme.bodyMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.8),
              ));

    final showDefaultBack = leading == null && onBack != null;
    final resolvedLeading =
        leading ??
        (showDefaultBack
            ? IconButton(
                onPressed: () => _handleBack(context),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.arrow_back, color: onPrimary),
              )
            : null);

    final Widget titleLine;
    if (titleWidget != null && title.isNotEmpty) {
      titleLine = Row(
        children: [
          titleWidget!,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: resolvedTitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (titleWidget != null) {
      titleLine = titleWidget!;
    } else {
      titleLine = Text(
        title,
        style: resolvedTitleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final bar = Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: expanded
          ? EdgeInsets.fromLTRB(16, 24 + statusBarHeight, 24, 24)
          : EdgeInsets.fromLTRB(16, 16 + statusBarHeight, 8, 16),
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          ?resolvedLeading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleLine,
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: resolvedSubtitleStyle),
              ],
            ),
          ),
          ...?actions,
        ],
      ),
    );

    if (expanded) {
      return Padding(padding: const EdgeInsets.only(bottom: 16), child: bar);
    }

    return bar;
  }
}
