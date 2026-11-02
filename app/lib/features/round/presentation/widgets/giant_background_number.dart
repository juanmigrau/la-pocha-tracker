import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

/// Placement of the watermark number within the parent [Stack].
enum GiantBackgroundNumberPlacement {
  /// Centered in the available area (scoring).
  center,

  /// Anchored above the bottom action button (bidding / play).
  bottom,
}

/// Semi-transparent giant number rendered behind interactive content.
///
/// Must be placed as a [Stack] layer under the page body. Uses
/// [IgnorePointer] so taps reach the content above.
class GiantBackgroundNumber extends StatelessWidget {
  const GiantBackgroundNumber({
    super.key,
    required this.label,
    required this.color,
    this.displayValue,
    this.signedValue,
    this.placement = GiantBackgroundNumberPlacement.center,
    this.fontSizeFactor = 0.6,
    this.numberOpacity = 0.20,
    this.labelOpacity = 0.25,
    this.bottom = 90,
  }) : assert(
         displayValue != null || signedValue != null,
         'Provide displayValue or signedValue',
       );

  /// Plain numeric text (e.g. bidding total). Ignored when [signedValue] is set.
  final String? displayValue;

  /// When set, renders a signed [RichText] with a smaller sign glyph.
  final int? signedValue;

  final String label;
  final Color color;
  final GiantBackgroundNumberPlacement placement;
  final double fontSizeFactor;
  final double numberOpacity;
  final double labelOpacity;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final isBottom = placement == GiantBackgroundNumberPlacement.bottom;
    final content = IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => _buildNumber(constraints),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isBottom ? 25 : 26,
              color: color.withValues(alpha: labelOpacity),
              letterSpacing: isBottom ? 1.4 : 1.5,
            ),
          ),
        ],
      ),
    );

    return switch (placement) {
      GiantBackgroundNumberPlacement.center => Positioned.fill(
        child: IgnorePointer(child: Center(child: content)),
      ),
      GiantBackgroundNumberPlacement.bottom => Positioned(
        bottom: bottom,
        left: 0,
        right: 0,
        child: content,
      ),
    };
  }

  Widget _buildNumber(BoxConstraints constraints) {
    final fontSize = constraints.maxWidth * fontSizeFactor;
    final numberColor = color.withValues(alpha: numberOpacity);

    if (signedValue != null) {
      final value = signedValue!;
      return SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value < 0 ? '-' : '+',
                style: TextStyle(
                  fontSize: fontSize * 0.55,
                  fontWeight: FontWeight.w900,
                  color: numberColor,
                  height: 1.0,
                ),
              ),
              Text(
                value.abs().toString(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: numberColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: constraints.maxWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayValue!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: numberColor,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Shared scaffold for [GiantBackgroundNumber] previews (`Positioned` needs a [Stack]).
Widget giantBackgroundNumberPreviewShell(Widget child) {
  return Theme(
    data: AppTheme.light,
    child: ColoredBox(
      color: AppTheme.surface,
      child: Stack(fit: StackFit.expand, children: [child]),
    ),
  );
}

/// Default preview chrome for [GiantBackgroundNumber] variants.
final class GiantNumberPreview extends Preview {
  const GiantNumberPreview({super.name})
    : super(
        group: 'GiantBackgroundNumber',
        size: const Size(390, 420),
        wrapper: giantBackgroundNumberPreviewShell,
      );
}

@GiantNumberPreview(name: 'Apuestas — prohibido (verde)')
Widget giantNumberBiddingRemainingPreview() {
  return const GiantBackgroundNumber(
    displayValue: '3',
    label: 'prohibido',
    color: AppTheme.primary,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.10,
    labelOpacity: 0.28,
  );
}

@GiantNumberPreview(name: 'Apuestas — prohibido 0 (rojo)')
Widget giantNumberBiddingZeroPreview() {
  return GiantBackgroundNumber(
    displayValue: '0',
    label: 'prohibido',
    color: AppTheme.light.colorScheme.error,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.10,
    labelOpacity: 0.28,
  );
}

@GiantNumberPreview(name: 'Apuestas — bazas de más (+)')
Widget giantNumberBiddingExcessPreview() {
  return GiantBackgroundNumber(
    signedValue: 2,
    label: 'bazas de más',
    color: AppTheme.light.colorScheme.error,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.10,
    labelOpacity: 0.28,
  );
}

@GiantNumberPreview(name: 'Apuestas — selección prohibida (opacidad ↑)')
Widget giantNumberBiddingForbiddenHighlightPreview() {
  return GiantBackgroundNumber(
    displayValue: '2',
    label: 'prohibido',
    color: AppTheme.light.colorScheme.error,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.6,
    labelOpacity: 0.616,
  );
}

@GiantNumberPreview(name: 'En juego — balance negativo (−)')
Widget giantNumberPlayUnderPreview() {
  return const GiantBackgroundNumber(
    signedValue: -2,
    label: 'balance',
    color: AppTheme.primary,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.10,
    labelOpacity: 0.28,
  );
}

@GiantNumberPreview(name: 'En juego — balance positivo (+)')
Widget giantNumberPlayOverPreview() {
  return GiantBackgroundNumber(
    signedValue: 3,
    label: 'balance',
    color: AppTheme.light.colorScheme.error,
    placement: GiantBackgroundNumberPlacement.bottom,
    fontSizeFactor: 0.72,
    numberOpacity: 0.10,
    labelOpacity: 0.28,
  );
}
