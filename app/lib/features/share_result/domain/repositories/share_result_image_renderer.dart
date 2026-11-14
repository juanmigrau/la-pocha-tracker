import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';

/// Port injected into the cubit to render a PNG file for sharing.
abstract class ShareResultImageRenderer {
  Future<String> renderPngFile(ShareResultPayload payload);
}
