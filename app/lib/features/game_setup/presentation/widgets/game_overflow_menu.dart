import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/features/game_setup/presentation/bloc/cancel_game_cubit.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/cancel_game_dialog.dart';

class GameOverflowMenu extends StatelessWidget {
  const GameOverflowMenu({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CancelGameCubit>(),
      child: _GameOverflowMenuView(gameId: gameId),
    );
  }
}

class _GameOverflowMenuView extends StatelessWidget {
  const _GameOverflowMenuView({
    required this.gameId,
  });

  final String gameId;

  Future<void> _confirmAndCancel(BuildContext context) async {
    final cubit = context.read<CancelGameCubit>();
    final confirmed = await showCancelGameDialog(context);
    if (confirmed) {
      await cubit.cancel(gameId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CancelGameCubit, CancelGameState>(
      listener: (context, state) {
        if (state is CancelGameSuccess) {
          context.go('/');
        } else if (state is CancelGameFailure) {
          SnackBarHelper.showError(state.message, context: context);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Ver tabla de puntos',
            onPressed: () => context.push('/games/$gameId/scorecard'),
            icon: const Icon(Icons.bar_chart, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Cancelar partida',
            onPressed: () => _confirmAndCancel(context),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
