import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:la_pocha/core/widgets/pocha_logo.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/domain/repositories/share_result_image_renderer.dart';
import 'package:la_pocha/features/share_result/presentation/widgets/share_result_card.dart';
import 'package:path_provider/path_provider.dart';

typedef TemporaryDirectoryGetter = Future<Directory> Function();

/// Renders [ShareResultCard] via an isolated render tree to a fixed PNG path.
class ShareResultImageRendererImpl implements ShareResultImageRenderer {
  ShareResultImageRendererImpl({
    TemporaryDirectoryGetter? getTemporaryDirectoryFn,
    this.pixelRatio = 3.0,
    this.fileName = 'la_pocha_share_result.png',
  }) : _getTemporaryDirectory =
           getTemporaryDirectoryFn ?? getTemporaryDirectory;

  static const Size logicalSize = ShareResultCard.logicalSize;

  final TemporaryDirectoryGetter _getTemporaryDirectory;
  final double pixelRatio;
  final String fileName;

  @override
  Future<String> renderPngFile(ShareResultPayload payload) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _precacheFanImage();

    final pngBytes = await _capturePng(payload);
    final directory = await _getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }

  Future<void> _precacheFanImage() async {
    final imageProvider = AssetImage(PochaLogo.fanAssetPath);
    final configuration = ImageConfiguration(
      devicePixelRatio: pixelRatio,
      size: const Size(36, 36),
    );
    final completer = Completer<void>();
    final stream = imageProvider.resolve(configuration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      stream.removeListener(listener);
    } catch (_) {
      stream.removeListener(listener);
    }
  }

  Future<Uint8List> _capturePng(ShareResultPayload payload) async {
    final view = ui.PlatformDispatcher.instance.views.first;
    final logicalConstraints = BoxConstraints.tight(logicalSize);
    final physicalSize = Size(
      logicalSize.width * pixelRatio,
      logicalSize.height * pixelRatio,
    );
    final physicalConstraints = BoxConstraints.tight(physicalSize);

    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        physicalConstraints: physicalConstraints,
        logicalConstraints: logicalConstraints,
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final pipelineOwner = PipelineOwner(onNeedVisualUpdate: () {});
    final buildOwner = BuildOwner(focusManager: FocusManager());
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: ShareResultCard(payload: payload),
    ).attachToRenderTree(buildOwner);

    void flushTree() {
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
    }

    flushTree();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    flushTree();

    final ui.Image image = await repaintBoundary.toImage(
      pixelRatio: pixelRatio,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw StateError('Failed to encode share result PNG');
    }
    return byteData.buffer.asUint8List();
  }
}
