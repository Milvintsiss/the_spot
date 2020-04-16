import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> convertImageFileToBitmapDescriptor(File imageFile,
    {int size = 150,
    bool addBorder = false,
    Color borderColor = Colors.white,
    double borderSize = 10,
    String title,
    Color titleColor = Colors.white,
    Color titleBackgroundColor = Colors.black}) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color;
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final double radius = size / 2;

  //make canvas clip path to prevent image drawing over the circle
  final Path clipPath = Path();
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Radius.circular(100)));
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 3 / 10),
      Radius.circular(100)));
  canvas.clipPath(clipPath);

  //paintImage
  final Uint8List imageUint8List = await imageFile.readAsBytes();
  final ui.Codec codec = await ui.instantiateImageCodec(imageUint8List);
  final ui.FrameInfo imageFI = await codec.getNextFrame();
  paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      image: imageFI.image);

  if (addBorder) {
    //draw Border
    paint..color = borderColor;
    paint..style = PaintingStyle.stroke;
    paint..strokeWidth = borderSize;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }

  if (title != null) {
    if (title.length > 9) {
      title = title.substring(0, 9);
    }
    //draw Title background
    paint..color = titleBackgroundColor;
    paint..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, size * 8 / 10, size.toDouble(), size * 3 / 10),
            Radius.circular(100)),
        paint);

    //draw Title
    textPainter.text = TextSpan(
        text: title,
        style: TextStyle(
          fontSize: radius / 2.5,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ));
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(radius - textPainter.width / 2,
            size * 9.5 / 10 - textPainter.height / 2));
  }

  //convert canvas as PNG bytes
  final _image =
      await pictureRecorder.endRecording().toImage(size, (size * 1.1).toInt());
  final data = await _image.toByteData(format: ui.ImageByteFormat.png);

  //convert PNG bytes as BitmapDescriptor
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}

Color transparentColor(Color color, int alpha) {
  return Color.fromARGB(alpha, color.red, color.green, color.blue);
}
