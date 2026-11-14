import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';

abstract class ShareSheetGateway {
  Future<ShareOutcome> shareImage({
    required String filePath,
    required String caption,
    ShareOrigin? origin,
  });
}
