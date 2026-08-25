import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/home/presentation/bloc/home_bloc.dart';
import 'package:la_pocha/features/home/presentation/widgets/debug_config_panel.dart';
import 'package:la_pocha/features/home/presentation/widgets/recent_game_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const _registrationBannerDismissedKey = 'registration_banner_dismissed';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final GlobalKey<DebugConfigPanelState> _debugPanelKey =
      GlobalKey<DebugConfigPanelState>();
  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  bool _bannerDismissed = true;
  bool _bannerPrefsLoaded = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.disable();
    _loadBannerDismissed();
  }

  Future<void> _loadBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _bannerDismissed = prefs.getBool(_registrationBannerDismissedKey) ?? false;
      _bannerPrefsLoaded = true;
    });
  }

  Future<void> _dismissRegistrationBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registrationBannerDismissedKey, true);
    if (!mounted) {
      return;
    }
    setState(() => _bannerDismissed = true);
  }

  void _onNewGamePressed() {
    if (kDebugMode) {
      final committed = _debugPanelKey.currentState?.commitSequence() ?? true;
      if (!committed) {
        SnackBarHelper.showError('Secuencia inválida. Revisa el formato.');
        return;
      }
    }
    context.push('/games/new');
  }

  void _onAccountPressed({required bool isAuthenticated}) {
    if (isAuthenticated) {
      context.push('/profile');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => const _AccountBenefitsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            PochaAppBar(
              title: 'La Pocha',
              subtitle: 'Marcador de puntos',
              expanded: true,
              actions: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isAuthenticated = state is Authenticated;
                    final user = isAuthenticated ? state.user : null;
                    final photoURL = user?.photoUrl;
                    final hasPhoto =
                        user != null && photoURL != null && photoURL.isNotEmpty;
                    final icon = hasPhoto
                        ? PlayerInitialAvatar(
                            name: user.displayName,
                            colorIndex: 0,
                            photoURL: photoURL,
                            radius: 16,
                          )
                        : const Icon(
                            Icons.account_circle_outlined,
                            color: Colors.white,
                          );
                    return IconButton(
                      onPressed: () =>
                          _onAccountPressed(isAuthenticated: isAuthenticated),
                      icon: isAuthenticated ? icon : Badge(child: icon),
                      tooltip: 'Mi cuenta',
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: PrimaryButton(
                label: 'Nueva partida',
                icon: Icons.add,
                onPressed: _onNewGamePressed,
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final showBanner =
                    _bannerPrefsLoaded &&
                    !_bannerDismissed &&
                    authState is Unauthenticated;
                if (!showBanner) {
                  return const SizedBox.shrink();
                }
                return _RegistrationBanner(
                  onRegister: () => context.go('/auth/sign-up'),
                  onDismiss: _dismissRegistrationBanner,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'ÚLTIMAS PARTIDAS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  return switch (state) {
                    HomeLoading() || HomeInitial() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    HomeLoaded(:final recentGames) => _RecentGamesList(
                      games: recentGames,
                    ),
                    HomeEmpty() => const _RecentGamesEmpty(),
                    HomeFailure(:final message) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  };
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/rules'),
                icon: const Icon(Icons.help_outline),
                label: const Text('¿Cómo se juega?'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            if (kDebugMode) DebugConfigPanel(key: _debugPanelKey),
            FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final info = snapshot.data!;
                final versionLabel = kDebugMode
                    ? 'v${info.version}+${info.buildNumber} (debug)'
                    : 'v${info.version}';
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Text(
                    versionLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationBanner extends StatelessWidget {
  const _RegistrationBanner({
    required this.onRegister,
    required this.onDismiss,
  });

  final VoidCallback onRegister;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_outlined,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guarda tu historial en la nube',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regístrate gratis para acceder a tus partidas '
                  'desde cualquier dispositivo y ver tus estadísticas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRegister,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Registrarse →'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: 18,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
            ),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _AccountBenefitsSheet extends StatelessWidget {
  const _AccountBenefitsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Por qué registrarse?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _BenefitRow(
              icon: Icons.history,
              text: 'Accede a tu historial desde cualquier dispositivo',
            ),
            const _BenefitRow(
              icon: Icons.bar_chart,
              text: 'Consulta tus estadísticas personales',
            ),
            const _BenefitRow(
              icon: Icons.cloud_done,
              text: 'Tus partidas se guardan automáticamente en la nube',
            ),
            const _BenefitRow(
              icon: Icons.people,
              text:
                  'Los demás jugadores registrados reciben la partida '
                  'en su historial',
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Crear cuenta gratis',
              onPressed: () {
                Navigator.pop(context);
                context.go('/auth/sign-up');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/auth/sign-in');
              },
              child: const Text('Ya tengo cuenta — Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _RecentGamesList extends StatelessWidget {
  const _RecentGamesList({required this.games});

  final List<GameHistoryItem> games;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < games.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          RecentGameTile(
            item: games[index],
            onTap: () =>
                context.push('/history/${games[index].id}?source=local'),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/history'),
            child: Text(
              'Ver todas →',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentGamesEmpty extends StatelessWidget {
  const _RecentGamesEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.style,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera partida para empezar',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
