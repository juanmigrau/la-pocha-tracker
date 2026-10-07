import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/di/injection.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/presentation/widgets/repeat_round_dialog.dart';

class RepeatRoundTextButton extends StatelessWidget {
  const RepeatRoundTextButton({
    super.key,
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RepeatRoundCubit>(),
      child: _RepeatRoundTextButtonView(
        gameId: gameId,
        roundNumber: roundNumber,
      ),
    );
  }
}

class _RepeatRoundTextButtonView extends StatelessWidget {
  const _RepeatRoundTextButtonView({
    required this.gameId,
    required this.roundNumber,
  });

  final String gameId;
  final int roundNumber;

  Future<void> _confirmAndRepeat(BuildContext context) async {
    final cubit = context.read<RepeatRoundCubit>();
    final confirmed = await showRepeatRoundDialog(context);
    if (confirmed) {
      await cubit.repeat(
        gameId: gameId,
        roundNumber: roundNumber,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RepeatRoundCubit, RepeatRoundState>(
      listener: (context, state) {
        if (state is RepeatRoundSuccess) {
          context.go(
            '/games/${state.gameId}/rounds/${state.roundNumber}/bids',
          );
        } else if (state is RepeatRoundFailure) {
          SnackBarHelper.showError(state.message, context: context);
        }
      },
      child: TextButton(
        onPressed: () => _confirmAndRepeat(context),
        child: const Text('Repetir esta ronda'),
      ),
    );
  }
}
