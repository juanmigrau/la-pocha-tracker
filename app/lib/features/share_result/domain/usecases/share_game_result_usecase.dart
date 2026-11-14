import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_sheet_gateway.dart';

class ShareGameResultUseCase {
  ShareGameResultUseCase(this._gateway);

  final ShareSheetGateway _gateway;

  Future<ShareOutcome> call({
    required String imageFilePath,
    required String caption,
    ShareOrigin? origin,
  }) async {
    if (imageFilePath.trim().isEmpty) {
      throw ArgumentError.value(
        imageFilePath,
        'imageFilePath',
        'Image path must not be empty',
      );
    }
    if (caption.trim().isEmpty) {
      throw ArgumentError.value(
        caption,
        'caption',
        'Caption must not be empty',
      );
    }

    return _gateway.shareImage(
      filePath: imageFilePath,
      caption: caption,
      origin: origin,
    );
  }
}
