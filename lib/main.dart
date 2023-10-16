// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DrawingApp(),
    );
  }
}

class DrawingApp extends StatefulWidget {
  @override
  _DrawingAppState createState() => _DrawingAppState();
}

class _DrawingAppState extends State<DrawingApp> {
  List<Offset> points = [];
  final globalKey = GlobalKey();

  Future<void> uploadImageToAPI() async {
    final buffer = await convertToImageData();
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
        title: const Text('Image Upload'),
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

  Future<Uint8List> convertToImageData() async {
    final RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 0.3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return Future.value(buffer);
  }

  Future<void> _saveAsImage() async {
    try {
      final buffer = await convertToImageData();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing App'),
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            points.add(details
                .localPosition); // Use localPosition instead of globalPosition
          });
        },
        onPanEnd: (details) async {
          // await _saveAsImage();
          await uploadImageToAPI();
          setState(() {
            points.clear();
          });
        },
        child: RepaintBoundary(
          key: globalKey,
          child: CustomPaint(
            painter: DrawingPainter(points),
            size: Size.infinite,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            points.clear();
          });
        },
        child: const Icon(Icons.clear),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 254, 228, 1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
