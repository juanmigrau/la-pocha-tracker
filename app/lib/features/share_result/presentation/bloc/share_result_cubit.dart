import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_result_image_renderer.dart';
import 'package:la_pocha/features/share_result/domain/usecases/build_share_result_caption_usecase.dart';
import 'package:la_pocha/features/share_result/domain/usecases/share_game_result_usecase.dart';

part 'share_result_state.dart';

const shareResultFailureMessage = 'No se pudo compartir. Inténtalo de nuevo.';

class ShareResultCubit extends Cubit<ShareResultState> {
  ShareResultCubit({
    required this._buildCaption,
    required this._imageRenderer,
    required this._shareGameResult,
  }) : super(const ShareResultInitial());

  final BuildShareResultCaptionUseCase _buildCaption;
  final ShareResultImageRenderer _imageRenderer;
  final ShareGameResultUseCase _shareGameResult;

  Future<void> share({
    required ShareResultPayload payload,
    ShareOrigin? origin,
  }) async {
    emit(const ShareResultInProgress());
    try {
      final caption = _buildCaption(payload);
      final imagePath = await _imageRenderer.renderPngFile(payload);
      final outcome = await _shareGameResult(
        imageFilePath: imagePath,
        caption: caption,
        origin: origin,
      );

      switch (outcome) {
        case ShareOutcome.shared:
        case ShareOutcome.unavailable:
          emit(const ShareResultSuccess());
        case ShareOutcome.dismissed:
          emit(const ShareResultInitial());
      }
    } catch (_) {
      emit(const ShareResultFailure(message: shareResultFailureMessage));
    }
  }
}
