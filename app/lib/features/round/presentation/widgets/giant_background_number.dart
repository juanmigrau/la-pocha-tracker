import 'package:flutter/material.dart';

/// Semi-transparent giant number rendered behind interactive content.
///
/// Must be placed as a [Stack] layer under the page body. Uses
/// [IgnorePointer] so taps reach the content above.
class GiantBackgroundNumber extends StatelessWidget {
  const GiantBackgroundNumber({
    super.key,
    required this.displayValue,
    required this.label,
    required this.color,
  });

  final String displayValue;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) => Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.55,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 0.09),
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 160),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.25),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
