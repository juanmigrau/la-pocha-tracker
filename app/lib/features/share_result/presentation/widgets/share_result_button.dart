import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/utils/snack_bar_helper.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/presentation/bloc/share_result_cubit.dart';

/// Share CTA. Hidden when [payload.ranking] is empty.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({super.key, required this.payload, this.iconColor});

  final ShareResultPayload payload;
  final Color? iconColor;

  ShareOrigin? _originFromContext(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final offset = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    return ShareOrigin(
      x: offset.dx,
      y: offset.dy,
      width: size.width,
      height: size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (payload.ranking.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocListener<ShareResultCubit, ShareResultState>(
      listener: (context, state) {
        if (state is ShareResultFailure) {
          SnackBarHelper.showError(state.message, context: context);
        }
      },
      child: BlocBuilder<ShareResultCubit, ShareResultState>(
        builder: (context, state) {
          final isLoading = state is ShareResultInProgress;
          final color = iconColor ?? Theme.of(context).colorScheme.onPrimary;

          return IconButton(
            tooltip: 'Compartir',
            onPressed: isLoading
                ? null
                : () {
                    final origin = _originFromContext(context);
                    context.read<ShareResultCubit>().share(
                      payload: payload,
                      origin: origin,
                    );
                  },
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(Icons.ios_share, color: color),
          );
        },
      ),
    );
  }
}
