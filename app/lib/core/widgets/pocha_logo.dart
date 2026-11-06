import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';

class PochaLogo extends StatelessWidget {
  const PochaLogo({
    super.key,
    this.height = 40.0,
    this.title = 'La Pocha',
  });

  static const String fanAssetPath = 'assets/images/la_pocha_fan.png';

  final double height;
  final String title;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            fanAssetPath,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          SizedBox(width: height * 0.2),
          Text(
            title,
            style: GoogleFonts.lilitaOne(
              fontSize: height * 0.7,
              color: onPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [PochaLogo] inside a real [PochaAppBar], as on the home screen.
Widget pochaLogoPreviewShell(Widget child) {
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
  final onPrimary = AppTheme.light.colorScheme.onPrimary;
  return PochaAppBar(
    titleWidget: const PochaLogo(height: 40),
    subtitle: 'Marcador de puntos',
    subtitleStyle: GoogleFonts.nunitoSans(
      textStyle: AppTheme.light.textTheme.bodyMedium,
      color: onPrimary.withValues(alpha: 0.8),
    ),
    expanded: true,
    actions: [
      Icon(Icons.brightness_auto, color: onPrimary),
      const SizedBox(width: 8),
      Icon(Icons.account_circle_outlined, color: onPrimary),
      const SizedBox(width: 8),
    ],
  );
}

@PochaLogoPreview(name: 'Compact AppBar')
Widget pochaLogoCompactAppBarPreview() {
  return const PochaAppBar(titleWidget: PochaLogo(height: 40));
}
