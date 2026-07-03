import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;

class ImageCropService {
  static Future<File?> cropImageFile(
    File imageFile,
    Rect analysisRegion,
    Size analysisImageSize,
  ) async {
    if (analysisImageSize.width <= 0 || analysisImageSize.height <= 0) {
      return imageFile;
    }

    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return imageFile;

    final oriented = img.bakeOrientation(original);
    final fullWidth = oriented.width.toDouble();
    final fullHeight = oriented.height.toDouble();

    final scaleX = fullWidth / analysisImageSize.width;
    final scaleY = fullHeight / analysisImageSize.height;

    final cropRect = Rect.fromLTRB(
      analysisRegion.left * scaleX,
      analysisRegion.top * scaleY,
      analysisRegion.right * scaleX,
      analysisRegion.bottom * scaleY,
    ).intersect(Rect.fromLTWH(0, 0, fullWidth, fullHeight));

    if (cropRect.width < 1 || cropRect.height < 1) {
      return imageFile;
    }

    final cropped = img.copyCrop(
      oriented,
      x: cropRect.left.round(),
      y: cropRect.top.round(),
      width: cropRect.width.round(),
      height: cropRect.height.round(),
    );

    final encoded = img.encodeJpg(cropped, quality: 95);
    await imageFile.writeAsBytes(encoded, flush: true);
    return imageFile;
  }
}
