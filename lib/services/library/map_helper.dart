import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:the_spot/services/library/mapmarker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme.dart';

/// In here we are encapsulating all the logic required to get marker icons from url images
/// and to show clusters using the [Fluster] package.
class MapHelper {
  /// If there is a cached file and it's not old returns the cached marker image file
  /// else it will download the image and save it on the temp dir and return that file.
  ///
  /// This mechanism is possible using the [DefaultCacheManager] package and is useful
  /// to improve load times on the next map loads, the first time will always take more
  /// time to download the file and set the marker image.
  ///
  /// You can resize the marker image by providing a [targetWidth].
  static Future<BitmapDescriptor> getMarkerImageFromUrl(
      String url, {
        int targetWidth,
      }) async {
    assert(url != null);

    final File markerImageFile = await DefaultCacheManager().getSingleFile(url);

    Uint8List markerImageBytes = await markerImageFile.readAsBytes();

    if (targetWidth != null) {
      markerImageBytes = await _resizeImageBytes(
        markerImageBytes,
        targetWidth,
      );
    }

    return BitmapDescriptor.fromBytes(markerImageBytes);
  }

  /// Draw a [clusterColor] circle with the [clusterSize] text inside that is [width] wide.
  ///
  /// Then it will convert the canvas to an image and generate the [BitmapDescriptor]
  /// to be used on the cluster marker icons.
  static Future<BitmapDescriptor> _getClusterMarker(
      int clusterSize,
      Color clusterColor,
      Color textColor,
      int width,
      ) async {
    assert(clusterSize != null);
    assert(clusterColor != null);
    assert(width != null);

    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = clusterColor;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final double radius = width / 2;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );

    textPainter.text = TextSpan(
      text: clusterSize.toString(),
      style: TextStyle(
        fontSize: radius - 5,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(
      radius.toInt() * 2,
      radius.toInt() * 2,
    );
    final data = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  /// Resizes the given [imageBytes] with the [targetWidth].
  ///
  /// We don't want the marker image to be too big so we might need to resize the image.
  static Future<Uint8List> _resizeImageBytes(
      Uint8List imageBytes,
      int targetWidth,
      ) async {
    assert(imageBytes != null);
    assert(targetWidth != null);

    final Codec imageCodec = await instantiateImageCodec(
      imageBytes,
      targetWidth: targetWidth,
    );

    final FrameInfo frameInfo = await imageCodec.getNextFrame();

    final ByteData byteData = await frameInfo.image.toByteData(
      format: ImageByteFormat.png,
    );

    return byteData.buffer.asUint8List();
  }

  /// Inits the cluster manager with all the [MapMarker] to be displayed on the map.
  /// Here we're also setting up the cluster marker itself, also with an [clusterImageUrl].
  ///
  /// For more info about customizing your clustering logic check the [Fluster] constructor.
  static Future<Fluster<MapMarker>> initClusterManager(
      List<MapMarker> markers,
      int minZoom,
      int maxZoom,
      ) async {
    assert(markers != null);
    assert(minZoom != null);
    assert(maxZoom != null);

    return Fluster<MapMarker>(
      minZoom: minZoom,
      maxZoom: maxZoom,
      radius: 150,
      extent: 2048,
      nodeSize: 64,
      points: markers,
      createCluster: (
          BaseCluster cluster,
          double lng,
          double lat,
          ) =>
          MapMarker(
            id: cluster.id.toString(),
            position: LatLng(lat, lng),
            isCluster: cluster.isCluster,
            clusterId: cluster.id,
            pointsSize: cluster.pointsSize,
            childMarkerId: cluster.childMarkerId,
          ),
    );
  }

  /// Gets a list of markers and clusters that reside within the visible bounding box for
  /// the given [currentZoom]. For more info check [Fluster.clusters].
  static Future<List<Marker>> getClusterMarkers(
      Fluster<MapMarker> clusterManager,
      double currentZoom,
      Color clusterColor,
      Color clusterTextColor,
      int clusterWidth,
      ) {
    assert(currentZoom != null);
    assert(clusterColor != null);
    assert(clusterTextColor != null);
    assert(clusterWidth != null);

    if (clusterManager == null) return Future.value([]);

    return Future.wait(clusterManager.clusters(
        [-180, -85, 180, 85], currentZoom.toInt()).map((mapMarker) async {
      if (mapMarker.isCluster) {
        mapMarker.icon = await _getClusterMarker(
          mapMarker.pointsSize,
          clusterColor,
          clusterTextColor,
          clusterWidth,
        );
      }

      return mapMarker.toMarker();
    }).toList());
  }
}

class ImageFileToBitmapDescriptor{
  File imageFile;
  int size;
  bool addBorder;
  Color borderColor;
  double borderSize;
  String title;
  Color titleColor;
  Color titleBackgroundColor;

  ImageFileToBitmapDescriptor(this.imageFile,
      {this.size = 150,
        this.addBorder = false,
        this.borderColor = Colors.white,
        this.borderSize = 10,
        this.title,
        this.titleColor = Colors.white,
        this.titleBackgroundColor = Colors.black});
}
Future<BitmapDescriptor> convertImageFileToBitmapDescriptor(ImageFileToBitmapDescriptor imageFileToBitmapDescriptor) async {

  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  final Paint paint = Paint()..color;
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final double radius = imageFileToBitmapDescriptor.size / 2;

  //make canvas clip path to prevent image drawing over the circle
  final Path clipPath = Path();
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, imageFileToBitmapDescriptor.size.toDouble(), imageFileToBitmapDescriptor.size.toDouble()),
      Radius.circular(1000)));
  clipPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, imageFileToBitmapDescriptor.size * 8 / 10, imageFileToBitmapDescriptor.size.toDouble(), imageFileToBitmapDescriptor.size * 2 / 10),
      Radius.circular(100)));
  canvas.clipPath(clipPath);

  if (imageFileToBitmapDescriptor.imageFile == null) {
    //paint Icon background
    paint..color = PrimaryColorLight;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    //paint Person Icon
    final icon = Icons.person;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
            fontSize: imageFileToBitmapDescriptor.size * 4 / 5,
            fontFamily: icon.fontFamily,
            color: PrimaryColorDark));
    textPainter.layout();
    textPainter.paint(canvas, Offset(imageFileToBitmapDescriptor.size * 1 / 10, imageFileToBitmapDescriptor.size * 1 / 10));
  } else {
    //paint Profile Picture
    final Uint8List imageUint8List = await imageFileToBitmapDescriptor.imageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(imageUint8List,
        targetHeight: imageFileToBitmapDescriptor.size, targetWidth: imageFileToBitmapDescriptor.size);
    final ui.FrameInfo imageFI = await codec.getNextFrame();
    paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, imageFileToBitmapDescriptor.size.toDouble(), imageFileToBitmapDescriptor.size.toDouble()),
        image: imageFI.image);
  }
  if (imageFileToBitmapDescriptor.addBorder) {
    //draw Border
    paint..color = imageFileToBitmapDescriptor.borderColor;
    paint..style = PaintingStyle.stroke;
    paint..strokeWidth = imageFileToBitmapDescriptor.borderSize;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }

  if (imageFileToBitmapDescriptor.title != null) {
    if (imageFileToBitmapDescriptor.title.length > 9) {
      imageFileToBitmapDescriptor.title = imageFileToBitmapDescriptor.title.substring(0, 9);
    }
    //draw Title background
    paint..color = imageFileToBitmapDescriptor.titleBackgroundColor;
    paint..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, imageFileToBitmapDescriptor.size * 8 / 10, imageFileToBitmapDescriptor.size.toDouble(), imageFileToBitmapDescriptor.size * 2 / 10),
            Radius.circular(100)),
        paint);

    //draw Title
    textPainter.text = TextSpan(
        text: imageFileToBitmapDescriptor.title,
        style: TextStyle(
          fontSize: radius / 2.5,
          fontWeight: FontWeight.bold,
          color: imageFileToBitmapDescriptor.titleColor,
        ));
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(radius - textPainter.width / 2,
            imageFileToBitmapDescriptor.size * 9 / 10 - textPainter.height / 2));
  }

  //convert canvas as PNG bytes
  final _image = await pictureRecorder.endRecording().toImage(imageFileToBitmapDescriptor.size, imageFileToBitmapDescriptor.size);
  final data = await _image.toByteData(format: ui.ImageByteFormat.png);

  //convert PNG bytes as BitmapDescriptor
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}
