import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widget_previews.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';

class PochaLogo extends StatelessWidget {
  const PochaLogo({super.key, this.height = 40.0});
  final double height;

  @override
  Widget build(BuildContext context) {
    final cardW = height * 0.55;
    final cardH = height * 0.85;
    final angles = [-48.0, -16.0, 16.0, 48.0];
    final colors = [
      const Color(0xFF7a8e70).withValues(alpha: 0.55),
      const Color(0xFF9aae8a).withValues(alpha: 0.71),
      const Color(0xFFbdd4aa).withValues(alpha: 0.87),
      const Color(0xFFdeeece).withValues(alpha: 1.0),
    ];

    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: height * 1.1,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(4, (i) {
                return Positioned.fill(
                  child: Transform.rotate(
                    angle: angles[i] * 3.14159265 / 180,
                    alignment: Alignment.bottomRight,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: cardW,
                        height: cardH,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(cardW * 0.12),
                          border: Border.all(
                            color: colors[i].withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.bold, height: 1.0),
              children: [
                TextSpan(
                  text: 'LA',
                  style: TextStyle(
                    fontSize: height * 0.45,
                    color: const Color(0xFFC8A84B),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' | ',
                  style: TextStyle(
                    fontSize: height * 0.5,
                    color: const Color(0xFFC8A84B).withValues(alpha: 0.6),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                TextSpan(
                  text: 'POCHA',
                  style: TextStyle(
                    fontSize: height * 0.68,
                    color: Colors.white,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [PochaLogo] inside a real [PochaAppBar], as on the home screen.
Widget pochaLogoPreviewShell(Widget child) {
  debugPaintSizeEnabled = true;
  return Theme(
    data: AppTheme.light,
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 160),
        padding: EdgeInsets.only(top: 24),
      ),
      child: ColoredBox(
        color: AppTheme.surface,
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    ),
  );
}

final class PochaLogoPreview extends Preview {
  const PochaLogoPreview({super.name})
    : super(
        group: 'PochaLogo',
        // Phone width × expanded PochaAppBar (~status bar + bar + bottom pad).
        size: const Size(390, 160),
        wrapper: pochaLogoPreviewShell,
      );
}

@PochaLogoPreview(name: 'Home — expanded')
Widget pochaLogoHomeAppBarPreview() {
  return PochaAppBar(
    titleWidget: const PochaLogo(height: 40),
    expanded: true,
    actions: [
      Icon(Icons.brightness_auto, color: AppTheme.light.colorScheme.onPrimary),
      const SizedBox(width: 8),
      Icon(
        Icons.account_circle_outlined,
        color: AppTheme.light.colorScheme.onPrimary,
      ),
      const SizedBox(width: 8),
    ],
  );
}

@PochaLogoPreview(name: 'Compact AppBar')
Widget pochaLogoCompactAppBarPreview() {
  return const PochaAppBar(titleWidget: PochaLogo(height: 40));
}
