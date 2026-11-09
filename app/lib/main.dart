import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/router/app_router.dart';
import 'package:la_pocha/core/router/auth_refresh_notifier.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/theme/theme_bloc.dart';
import 'package:la_pocha/core/widgets/root_scaffold_messenger_key.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/get_active_game_usecase.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:la_pocha/features/sync/presentation/widgets/sync_status_snackbar.dart';
import 'package:la_pocha/firebase_options.dart';

Future<void> main() async {
  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsFlutterBinding.ensureInitialized(),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();

  final resumeLocation = await _resolveResumeLocation();

  final authBloc = getIt<AuthBloc>()..add(const AuthStarted());
  final gameSyncBloc = getIt<GameSyncBloc>();
  final themeBloc = getIt<ThemeBloc>()..add(const ThemeStarted());
  final refreshNotifier = AuthRefreshNotifier(authBloc);
  final router = createAppRouter(
    refreshListenable: refreshNotifier,
    authBloc: authBloc,
    resumeLocation: resumeLocation,
  );

  FlutterNativeSplash.remove();
  runApp(
    LaPochaApp(
      authBloc: authBloc,
      gameSyncBloc: gameSyncBloc,
      themeBloc: themeBloc,
      router: router,
    ),
  );
}

Future<String?> _resolveResumeLocation() async {
  try {
    final activeGame = await getIt<GetActiveGameUseCase>()();
    final roundNumber = activeGame?.currentRoundNumber;
    if (activeGame == null || roundNumber == null) {
      return null;
    }

    final round = await getIt<RoundRepository>().getRoundByGameAndNumber(
      activeGame.id,
      roundNumber,
    );
    if (round == null) {
      return null;
    }

    final gameId = activeGame.id;
    return switch (round.status) {
      RoundStatus.bidding => '/games/$gameId/rounds/$roundNumber/bids',
      RoundStatus.playing => '/games/$gameId/rounds/$roundNumber/play',
      RoundStatus.closed => '/games/$gameId/rounds/$roundNumber/result',
    };
  } catch (_) {
    return null;
  }
}

class LaPochaApp extends StatelessWidget {
  const LaPochaApp({
    super.key,
    required this.authBloc,
    required this.gameSyncBloc,
    required this.themeBloc,
    required this.router,
  });

  final AuthBloc authBloc;
  final GameSyncBloc gameSyncBloc;
  final ThemeBloc themeBloc;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GameSyncBloc>.value(value: gameSyncBloc),
        BlocProvider<ThemeBloc>.value(value: themeBloc),
      ],
      child: SyncStatusSnackbar(
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return MaterialApp.router(
              title: 'La Pocha',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: state.themeMode,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              routerConfig: router,
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final iconBrightness = isDark
                    ? Brightness.light
                    : Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark
                        ? Brightness.dark
                        : Brightness.light,
                    statusBarBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarIconBrightness: iconBrightness,
                    systemNavigationBarContrastEnforced: false,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
