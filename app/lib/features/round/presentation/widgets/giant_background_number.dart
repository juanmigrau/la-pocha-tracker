import 'package:flutter/material.dart';

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
    this.fontSizeFactor = 0.55,
    this.numberOpacity = 0.09,
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
          LayoutBuilder(builder: (context, constraints) => _buildNumber(constraints)),
          Text(
            label,
            style: TextStyle(
              fontSize: isBottom ? 12 : 13,
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
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: value < 0 ? '-' : '+',
              style: TextStyle(
                fontSize: fontSize * 0.42,
                fontWeight: FontWeight.w900,
                color: numberColor,
                height: 1.2,
              ),
            ),
            TextSpan(
              text: value.abs().toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: numberColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      displayValue!,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: numberColor,
        height: 1.0,
      ),
    );
  }
}
