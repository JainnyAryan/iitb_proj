// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class Utils {
  Offset calcCirclePosition(
      int n, Size size, int dimension, double relativePadding) {
    final o = size.width > size.height
        ? Offset((size.width - size.height) / 2, 0)
        : Offset(0, (size.height - size.width) / 2);
    return o +
        Offset(
          size.shortestSide /
              (dimension - 1 + relativePadding * 2) *
              (n % dimension + relativePadding),
          size.shortestSide /
              (dimension - 1 + relativePadding * 2) *
              (n ~/ dimension + relativePadding),
        );
  }

  Future<Uint8List> convertOffsetsToImageData(
      List<Offset> offsets, List<double> canvasSize) async {
    final width = canvasSize[0]; // specify the width of the image (e.g., 500)
    final height = canvasSize[1]; // specify the height of the image (e.g., 500)

    final recorder = PictureRecorder();
    final canvas = Canvas(
        recorder,
        Rect.fromPoints(
            Offset(0, 0), Offset(width.toDouble(), height.toDouble())));

    final paint = Paint()
      ..color = Colors.black // Set the color you want for drawing
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    // Draw the pattern using the offsets
    for (int i = 0; i < offsets.length - 1; i++) {
      canvas.drawLine(offsets[i], offsets[i + 1], paint);
    }

    // Convert the image to a ByteData.
    final img =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return Future.value(buffer);
  }

  Future<void> uploadPatternToAPI(List<Offset> offsets, BuildContext context,
      List<double> canvasSize) async {
    final buffer = await convertOffsetsToImageData(offsets, canvasSize);
    String base64Image = base64Encode(buffer);
    final url =
        Uri.parse("http://iitbproj.pythonanywhere.com/upload_to_firebase");
    var response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64_image_encoded': base64Image,
        }));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pattern Upload'),
        content: Text(response.body),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsImage(List<Offset> offsets, BuildContext context,
      List<double> canvasSize) async {
    try {
      final buffer = await convertOffsetsToImageData(offsets, canvasSize);

      // Request permission to access the photo library
      var status = await Permission.mediaLibrary.request();

      if (status.isGranted) {
        // Permission granted, proceed to save the image
        final result =
            await ImageGallerySaver.saveImage(Uint8List.fromList(buffer));

        if (result['isSuccess']) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Image Saved'),
              content:
                  const Text('The drawing has been saved to your gallery.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          print('Failed to save the image.');
        }
      } else {
        // Permission denied, handle accordingly
        print('Permission denied to access the photo library.');
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
