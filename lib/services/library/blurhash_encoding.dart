

import 'dart:io';
import 'dart:math';

import 'dart:typed_data';
import 'package:image/image.dart' as img;

String getImageBlurHash(File file, {bool addWidthAndHeightToHash = false}){
  final Uint8List fileData = file.readAsBytesSync();
  final img.Image image = img.decodeImage(fileData.toList());
  final int imageWidth = image.width;
  final int imageHeight = image.height;
  String hash = encodeBlurHash(image.getBytes(format: img.Format.rgba), imageWidth, imageHeight);
  if(addWidthAndHeightToHash)
    hash = _addWidthAndHeightToHash(hash, imageWidth, imageHeight);
  print("BlurHash: $hash");
  return hash;
}

String _addWidthAndHeightToHash(String hash, int width, int height){
  return "$hash/$width/$height";
}

String getHashFromBlurHashWidthHeight (String blurHash){
  return blurHash.split("/")[0];
}

int getWidthFromBlurHashWidthHeight (String blurHash){
  return int.parse(blurHash.split("/")[1]);
}

int getHeightFromBlurHashWidthHeight (String blurHash){
  return int.parse(blurHash.split("/")[2]);
}

String encodeBlurHash(
    Uint8List data,
    int width,
    int height, {
      int numCompX = 4,
      int numpCompY = 3,
    }) {
  if (numCompX < 1 || numCompX > 9 || numpCompY < 1 || numCompX > 9) {
      print("BlurHash components must lie between 1 and 9.");
  }

  if (width * height * 4 != data.length) {
    print("The width and height must match the data array."
          "The expected format is RGBA32");
  }

  final factors = List<Color>(numCompX * numpCompY);
  int i = 0;
  for (var y = 0; y < numpCompY; ++y) {
    for (var x = 0; x < numCompX; ++x) {
      final normalisation = (x == 0 && y == 0) ? 1.0 : 2.0;
      final basisFunc = (int i, int j) {
        return normalisation *
            cos((pi * x * i) / width) *
            cos((pi * y * j) / height);
      };
      factors[i++] = _multiplyBasisFunction(data, width, height, basisFunc);
    }
  }

  final dc = factors.first;
  final ac = factors.skip(1).toList();

  final blurHash = StringBuffer();
  final sizeFlag = (numCompX - 1) + (numpCompY - 1) * 9;
  blurHash.write(encode83(sizeFlag, 1));

  var maxVal = 1.0;
  if (ac.isNotEmpty) {
    final maxElem = (Color c) => max(c.r.abs(), max(c.g.abs(), c.b.abs()));
    final actualMax = ac.map(maxElem).reduce(max);
    final quantisedMax = max(0, min(82, (actualMax * 166.0 - 0.5).floor()));
    maxVal = (quantisedMax + 1.0) / 166.0;
    blurHash.write(encode83(quantisedMax, 1));
  } else {
    blurHash.write(encode83(0, 1));
  }

  blurHash.write(encode83(encodeDC(dc), 4));
  for (final factor in ac) {
    blurHash.write(encode83(encodeAC(factor, maxVal), 2));
  }
  return blurHash.toString();
}


String encode83(int value, int length) {
  assert(value >= 0 && length >= 0);

  final buffer = StringBuffer();
  final chars = _encoding.keys.toList().asMap();
  for (var i = 1; i <= length; ++i) {
    final digit = (value / pow(83, length - i)) % 83;
    buffer.write(chars[digit.toInt()]);
  }
  return buffer.toString();
}

Color _multiplyBasisFunction(
    Uint8List pixels,
    int width,
    int height,
    double basisFunction(int i, int j),
    ) {
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;

  final bytesPerRow = width * 4;

  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final basis = basisFunction(x, y);
      r += basis * sRGBtoLinear(pixels[4 * x + 0 + y * bytesPerRow]);
      g += basis * sRGBtoLinear(pixels[4 * x + 1 + y * bytesPerRow]);
      b += basis * sRGBtoLinear(pixels[4 * x + 2 + y * bytesPerRow]);
    }
  }

  final scale = 1.0 / (width * height);
  return Color(r * scale, g * scale, b * scale);
}

class Color {
  Color(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;
}

Color decodeDC(int value) {
  final r = value >> 16;
  final g = (value >> 8) & 255;
  final b = value & 255;

  return Color(
    sRGBtoLinear(r),
    sRGBtoLinear(g),
    sRGBtoLinear(b),
  );
}

Color decodeAC(int value, double maxVal) {
  final r = value / (19.0 * 19.0);
  final g = (value / 19.0) % 19.0;
  final b = value % 19.0;

  return Color(
    signPow((r - 9.0) / 9.0, 2.0) * maxVal,
    signPow((g - 9.0) / 9.0, 2.0) * maxVal,
    signPow((b - 9.0) / 9.0, 2.0) * maxVal,
  );
}

int encodeDC(Color color) {
  final r = linearTosRGB(color.r);
  final g = linearTosRGB(color.g);
  final b = linearTosRGB(color.b);
  return (r << 16) + (g << 8) + b;
}

int encodeAC(Color color, double maxVal) {
  final r = max(0, min(18, signPow(color.r / maxVal, 0.5) * 9 + 9.5)).floor();
  final g = max(0, min(18, signPow(color.g / maxVal, 0.5) * 9 + 9.5)).floor();
  final b = max(0, min(18, signPow(color.b / maxVal, 0.5) * 9 + 9.5)).floor();
  return r * 19 * 19 + g * 19 + b;
}

double sRGBtoLinear(int value) {
  final v = value / 255.0;
  if (v <= 0.04045) return v / 12.92;
  return pow((v + 0.055) / 1.055, 2.4);
}

int linearTosRGB(double value) {
  final v = value.clamp(0.0, 1.0);
  if (v <= 0.0031308) return (v * 12.92 * 255.0 + 0.5).toInt();
  return ((1.055 * pow(v, 1.0 / 2.4) - 0.055) * 255.0 + 0.5).toInt();
}

double signPow(double value, double exp) {
  return pow(value.abs(), exp) * value.sign;
}

const _encoding = <String, int>{
  "0": 0,
  "1": 1,
  "2": 2,
  "3": 3,
  "4": 4,
  "5": 5,
  "6": 6,
  "7": 7,
  "8": 8,
  "9": 9,
  "A": 10,
  "B": 11,
  "C": 12,
  "D": 13,
  "E": 14,
  "F": 15,
  "G": 16,
  "H": 17,
  "I": 18,
  "J": 19,
  "K": 20,
  "L": 21,
  "M": 22,
  "N": 23,
  "O": 24,
  "P": 25,
  "Q": 26,
  "R": 27,
  "S": 28,
  "T": 29,
  "U": 30,
  "V": 31,
  "W": 32,
  "X": 33,
  "Y": 34,
  "Z": 35,
  "a": 36,
  "b": 37,
  "c": 38,
  "d": 39,
  "e": 40,
  "f": 41,
  "g": 42,
  "h": 43,
  "i": 44,
  "j": 45,
  "k": 46,
  "l": 47,
  "m": 48,
  "n": 49,
  "o": 50,
  "p": 51,
  "q": 52,
  "r": 53,
  "s": 54,
  "t": 55,
  "u": 56,
  "v": 57,
  "w": 58,
  "x": 59,
  "y": 60,
  "z": 61,
  "#": 62,
  r"$": 63,
  "%": 64,
  "*": 65,
  "+": 66,
  ",": 67,
  "-": 68,
  ".": 69,
  ":": 70,
  ";": 71,
  "=": 72,
  "?": 73,
  "@": 74,
  "[": 75,
  "]": 76,
  "^": 77,
  "_": 78,
  "{": 79,
  "|": 80,
  "}": 81,
  "~": 82
};