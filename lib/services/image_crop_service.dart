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

    final bool isAnalysisLandscape = analysisImageSize.width > analysisImageSize.height;
    final bool isCapturedLandscape = fullWidth > fullHeight;

    final double analysisW;
    final double analysisH;

    if (isAnalysisLandscape != isCapturedLandscape) {
      analysisW = analysisImageSize.height;
      analysisH = analysisImageSize.width;
    } else {
      analysisW = analysisImageSize.width;
      analysisH = analysisImageSize.height;
    }

    final scaleX = fullWidth / analysisW;
    final scaleY = fullHeight / analysisH;

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

  /// Applies a color matrix filter and optionally crops the image.
  static Future<File?> applyFilterAndCrop(
    File imageFile, {
    List<double>? colorMatrix,
    Rect? cropRect, // Rect in normalized coordinates (0-1) or pixel coords depending on context
    Size? analysisImageSize,
  }) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return imageFile;

    image = img.bakeOrientation(image);

    // 1. Apply Color Matrix Filter if provided
    if (colorMatrix != null && colorMatrix.length == 20) {
      // The 'image' package doesn't have a direct 4x5 color matrix application.
      // We'll iterate over pixels. This is slower but ensures the "theme" is saved.
      for (final pixel in image) {
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final a = pixel.a;

        final newR = (colorMatrix[0] * r + colorMatrix[1] * g + colorMatrix[2] * b + colorMatrix[3] * a + colorMatrix[4]).clamp(0, 255);
        final newG = (colorMatrix[5] * r + colorMatrix[6] * g + colorMatrix[7] * b + colorMatrix[8] * a + colorMatrix[9]).clamp(0, 255);
        final newB = (colorMatrix[10] * r + colorMatrix[11] * g + colorMatrix[12] * b + colorMatrix[13] * a + colorMatrix[14]).clamp(0, 255);
        
        pixel.r = newR.toInt();
        pixel.g = newG.toInt();
        pixel.b = newB.toInt();
      }
    }

    // 2. Apply Crop if provided
    if (cropRect != null && analysisImageSize != null) {
      final fullWidth = image.width.toDouble();
      final fullHeight = image.height.toDouble();

      // Ensure we account for potential orientation mismatch between analysis and raw image
      final bool isAnalysisLandscape = analysisImageSize.width > analysisImageSize.height;
      final bool isCapturedLandscape = fullWidth > fullHeight;

      final double effectiveAnalysisW;
      final double effectiveAnalysisH;

      if (isAnalysisLandscape != isCapturedLandscape) {
        effectiveAnalysisW = analysisImageSize.height;
        effectiveAnalysisH = analysisImageSize.width;
      } else {
        effectiveAnalysisW = analysisImageSize.width;
        effectiveAnalysisH = analysisImageSize.height;
      }

      final scaleX = fullWidth / effectiveAnalysisW;
      final scaleY = fullHeight / effectiveAnalysisH;

      final pixelCropRect = Rect.fromLTRB(
        cropRect.left * scaleX,
        cropRect.top * scaleY,
        cropRect.right * scaleX,
        cropRect.bottom * scaleY,
      ).intersect(Rect.fromLTWH(0, 0, fullWidth, fullHeight));

      if (pixelCropRect.width >= 1 && pixelCropRect.height >= 1) {
        image = img.copyCrop(
          image,
          x: pixelCropRect.left.round(),
          y: pixelCropRect.top.round(),
          width: pixelCropRect.width.round(),
          height: pixelCropRect.height.round(),
        );
      }
    }

    final encoded = img.encodeJpg(image, quality: 95);
    await imageFile.writeAsBytes(encoded, flush: true);
    return imageFile;
  }
}
