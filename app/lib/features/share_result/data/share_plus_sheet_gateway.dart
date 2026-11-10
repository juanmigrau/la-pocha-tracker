import 'dart:ui';

import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_sheet_gateway.dart';
import 'package:share_plus/share_plus.dart';

typedef ShareInvoker = Future<ShareResult> Function(ShareParams params);

class SharePlusSheetGateway implements ShareSheetGateway {
  SharePlusSheetGateway({ShareInvoker? share})
    : _share = share ?? ((params) => SharePlus.instance.share(params));

  final ShareInvoker _share;

  @override
  Future<ShareOutcome> shareImage({
    required String filePath,
    required String caption,
    ShareOrigin? origin,
  }) async {
    final result = await _share(
      ShareParams(
        files: [XFile(filePath)],
        text: caption,
        sharePositionOrigin: origin == null
            ? null
            : Rect.fromLTWH(origin.x, origin.y, origin.width, origin.height),
      ),
    );

    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unavailable,
    };
  }
}
