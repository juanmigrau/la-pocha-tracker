import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/widgets/pocha_app_bar.dart';
import 'package:la_pocha/core/widgets/primary_button.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/game_setup_bloc.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/dealer_roulette_scheduler.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/random_dealer_button.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/reorderable_player_list.dart';

class GameSetupPage extends StatelessWidget {
  const GameSetupPage({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<GameSetupBloc>()..add(GameSetupStarted(gameId: gameId)),
      child: _GameSetupView(gameId: gameId),
    );
  }
}

class _GameSetupView extends StatelessWidget {
  const _GameSetupView({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameSetupBloc, GameSetupState>(
      listener: (context, state) {
        if (state is GameSetupNavigateToBids) {
          context.go('/games/${state.gameId}/rounds/${state.roundNumber}/bids');
        }
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PochaAppBar(
                title: 'Orden de mesa',
                subtitle: 'Arrastra para reordenar',
                onBack: () => context.go('/games/$gameId/players'),
              ),
              Expanded(
                child: BlocBuilder<GameSetupBloc, GameSetupState>(
                  builder: (context, state) {
                    return switch (state) {
                      GameSetupLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      GameSetupFailure(:final message) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(message),
                        ),
                      ),
                      GameSetupLoaded(
                        :final players,
                        :final firstDealerPlayerId,
                        :final isStarting,
                        :final isComplete,
                      ) =>
                        _LoadedBody(
                          players: players,
                          firstDealerPlayerId: firstDealerPlayerId,
                          isStarting: isStarting,
                          isComplete: isComplete,
                        ),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.players,
    required this.firstDealerPlayerId,
    required this.isStarting,
    required this.isComplete,
  });

  final List<PlayerEmbed> players;
  final String firstDealerPlayerId;
  final bool isStarting;
  final bool isComplete;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody>
    with SingleTickerProviderStateMixin {
  DealerRouletteScheduler? _scheduler;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  /// Dealer id shown in the list/header while the roulette runs (previous).
  String? _visualDealerId;
  String? _highlightedPlayerId;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _scheduler?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  String get _displayedDealerId =>
      _visualDealerId ?? widget.firstDealerPlayerId;

  String get _dealerName {
    for (final player in widget.players) {
      if (player.id == _displayedDealerId) {
        return player.displayName;
      }
    }
    return '';
  }

  void _onRandomDealerPressed() {
    if (_isAnimating || widget.players.isEmpty) {
      return;
    }

    final previousDealerId = widget.firstDealerPlayerId;
    final playerIds = widget.players.map((p) => p.id).toList();

    // Freeze the visual dealer on the previous selection, then let the BLoC
    // predetermine the winner with the existing RandomDealerRequested logic.
    setState(() {
      _isAnimating = true;
      _visualDealerId = previousDealerId;
      _highlightedPlayerId = null;
    });

    context.read<GameSetupBloc>().add(const RandomDealerRequested());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = context.read<GameSetupBloc>().state;
      if (state is! GameSetupLoaded || state.players.isEmpty) {
        setState(() {
          _isAnimating = false;
          _visualDealerId = null;
          _highlightedPlayerId = null;
        });
        return;
      }

      final winnerId = state.firstDealerPlayerId;
      _scheduler?.cancel();
      _scheduler = DealerRouletteScheduler(
        playerIds: playerIds,
        winnerId: winnerId,
        onHighlight: (playerId) {
          if (!mounted) {
            return;
          }
          setState(() => _highlightedPlayerId = playerId);
        },
        onComplete: () => _onRouletteComplete(winnerId),
      )..start();
    });
  }

  Future<void> _onRouletteComplete(String winnerId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _highlightedPlayerId = winnerId;
      _visualDealerId = winnerId;
    });

    await _scaleController.forward(from: 0);

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnimating = false;
      _visualDealerId = null;
      // Keep a soft highlight on the winner until the next interaction clears it.
      _highlightedPlayerId = winnerId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionsEnabled = !_isAnimating && !widget.isStarting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.style,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _dealerName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return ReorderablePlayerList(
                  players: widget.players,
                  firstDealerPlayerId: _displayedDealerId,
                  highlightedPlayerId: _highlightedPlayerId,
                  winnerScale: _scaleAnimation.value,
                  onReorder: (oldIndex, newIndex) {
                    if (_isAnimating) {
                      return;
                    }
                    context.read<GameSetupBloc>().add(
                      PlayersReordered(oldIndex: oldIndex, newIndex: newIndex),
                    );
                  },
                  onDealerSelected: (playerId) {
                    if (_isAnimating) {
                      return;
                    }
                    setState(() => _highlightedPlayerId = null);
                    context.read<GameSetupBloc>().add(
                      FirstDealerSelected(playerId: playerId),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: RandomDealerButton(
            isEnabled: actionsEnabled && widget.isComplete,
            onPressed: _onRandomDealerPressed,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PrimaryButton(
            label: 'Empezar partida',
            icon: Icons.play_arrow,
            isLoading: widget.isStarting,
            onPressed: actionsEnabled && widget.isComplete
                ? () => context.read<GameSetupBloc>().add(
                    const StartGameRequested(),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
