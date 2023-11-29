// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Utils {
  List calcCirclePosition(int n, Size size, int dimension,
      double relativePadding, double circleRadiusCoefficient) {
    double angle = 2 * pi * (n / (dimension));
    double radius = (size.shortestSide / 2 -
        relativePadding * size.shortestSide / (dimension - 1));
    radius = radius * circleRadiusCoefficient;
    double x = size.width / 2 + radius * cos(angle);
    double y = size.height / 2 + radius * sin(angle);

    return [
      Offset(x, y),
      [cos(angle), sin(angle)]
    ];
  }

  // Map getJitterInfo(List<Offset> points) {
  //   Map jitter_info = {"max_jitter": 0, "avg_jitter": 0};
  //   List dists = [];
  //   for (int i = 0; i < points.length - 1; i++) {
  //     dists.add((points[i + 1] - points[i]).distance);
  //   }
  //   jitter_info["max_jitter"] =
  //       dists.reduce((value, element) => value > element ? value : element);
  //   jitter_info["avg_jitter"] = dists.isNotEmpty
  //       ? dists.reduce((value, element) => value + element) / dists.length
  //       : 0.0;

  //   return jitter_info;
  // }

  Map getJitterInfo(List<Offset> points) {
    Map jitterInfo = {"maxJitter": 0, "avgJitter": 0};
    List<double> distances = [];
    List<double> angles = [];

    for (int i = 0; i < points.length - 1; i++) {
      distances.add((points[i + 1] - points[i]).distance);
      angles.add(atan2(
          points[i + 1].dy - points[i].dy, points[i + 1].dx - points[i].dx));
    }

    List<double> angularDifferences = [];
    for (int i = 1; i < angles.length; i++) {
      angularDifferences.add((angles[i] - angles[i - 1]).abs());
    }

    List<double> curvatures = [];
    for (int i = 1; i < distances.length; i++) {
      if (distances[i - 1] != 0) {
        curvatures.add(angularDifferences[i - 1] / distances[i - 1]);
      }
    }

    if (curvatures.isNotEmpty) {
      jitterInfo["maxJitter"] = curvatures.reduce((value, element) =>
          value.isFinite
              ? (element.isFinite ? (value > element ? value : element) : value)
              : (element.isFinite ? element : 0));

      double totalLength = distances.fold(0, (prev, curr) => prev + curr);
      jitterInfo["avgJitter"] = curvatures.reduce((value, element) =>
              value.isFinite
                  ? (element.isFinite ? (value + element) : value)
                  : (element.isFinite ? element : 0)) /
          totalLength;
    }

    return jitterInfo;
  }

  Future<Uint8List> convertOffsetsToImageData({
    required List<Offset> offsets,
    required List<double> canvasSize,
    required List<int> times,
    required List<double> distances,
    required int duration,
    required Map<int, Offset> randomPointsPositions,
  }) async {
    final width = canvasSize[0];
    final height = canvasSize[1];

    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        const Offset(0, 0),
        Offset(
          width.toDouble(),
          height.toDouble(),
        ),
      ),
    );
    final paint = Paint()
      ..color = Colors.black // Set the color you want for drawing
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    // Draw the pattern using the offsets
    for (int i = 0; i < offsets.length - 1; i++) {
      canvas.drawLine(offsets[i], offsets[i + 1], paint);
    }

    // Draw the digit circles
    randomPointsPositions.forEach((digit, offset) {
      canvas.drawCircle(
        offset,
        20,
        paint,
      );

      // Draw the digit inside the circle
      final textPainter = TextPainter(
        text: TextSpan(
          text: digit.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20 * 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: 20 * 2);
      textPainter.paint(
        canvas,
        Offset(
          offset.dx - 20 * 0.3,
          offset.dy - 20 * 0.6,
        ),
      );
    });

    // Convert the image to a ByteData.
    final img =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return Future.value(buffer);
  }

  Future<String> uploadPatternToAPI({
    required List<Offset> offsets,
    required BuildContext context,
    required List<double> canvasSize,
    required List<int> times,
    required List<double> distances,
    required int duration,
    required Map<int, Offset> randomPointsPositions,
    List? jitterCsvData,
    List? jitterUserCsvData,
  }) async {
    final buffer = await convertOffsetsToImageData(
      offsets: offsets,
      canvasSize: canvasSize,
      times: times,
      distances: distances,
      duration: duration,
      randomPointsPositions: randomPointsPositions,
    );

    final timesString = times.map((time) => time.toString()).join(',');
    final distancesString =
        distances.map((distance) => distance.toString()).join(',');
    String jitterCsvDataString =
        jitterCsvData!.map((e) => (e as List).join(",")).toList().join("\n");

    jitterUserCsvData!.last = jitterUserCsvData.last.toString().replaceAll("\n", ". ");
    String jitterUserCsvDataString = jitterUserCsvData.join(",");
    print(jitterUserCsvDataString);

    String base64Image = base64Encode(buffer);
    final url =
        Uri.parse("https://iitbproj.pythonanywhere.com/upload_to_firebase");
    var response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'base64_image_encoded': base64Image,
          "timesString": timesString,
          "distancesString": distancesString,
          "duration": duration.toString(),
          "jitterCsvDataString": jitterCsvDataString,
          "jitterUserCsvDataString": jitterUserCsvDataString,
        }));

    return response.body;
  }

  // Future<void> _saveAsImage({
  //   required List<Offset> offsets,
  //   required BuildContext context,
  //   required List<double> canvasSize,
  //   required List<int> times,
  //   required List<double> distances,
  //   required int duration,
  // }) async {
  //   try {
  //     final buffer = await convertOffsetsToImageData(
  //       offsets: offsets,
  //       canvasSize: canvasSize,
  //       times: times,
  //       distances: distances,
  //       duration: duration,
  //     );
  //     // Request permission to access the photo library
  //     var status = await Permission.mediaLibrary.request();

  //     if (status.isGranted) {
  //       // Permission granted, proceed to save the image
  //       final result =
  //           await ImageGallerySaver.saveImage(Uint8List.fromList(buffer));

  //       if (result['isSuccess']) {
  //         showDialog(
  //           context: context,
  //           builder: (_) => AlertDialog(
  //             title: const Text('Image Saved'),
  //             content:
  //                 const Text('The drawing has been saved to your gallery.'),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text('OK'),
  //               ),
  //             ],
  //           ),
  //         );
  //       } else {
  //         print('Failed to save the image.');
  //       }
  //     } else {
  //       // Permission denied, handle accordingly
  //       print('Permission denied to access the photo library.');
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   }
  // }
}
