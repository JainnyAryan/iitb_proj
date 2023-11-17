// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'custom_pattern_lock.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pattern Lock Screen',
      home: PatternLockScreen(),
    );
  }
}

class PatternLockScreen extends StatefulWidget {
  const PatternLockScreen({Key? key}) : super(key: key);

  @override
  _PatternLockScreenState createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  String pattern = '';
  List points = [];

  final utils = Utils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture Pattern Lock'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.1,
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomPatternLock(
                    pointRadius: (constraints.maxHeight > constraints.maxWidth
                            ? constraints.maxWidth
                            : constraints.maxHeight) *
                        0.08,
                    circleRadiusCoefficient: 1,
                    showInput: true,
                    numberOfPoints: 9,
                    relativePadding: 0.5,
                    selectThreshold: 25,
                    fillPoints: true,
                    selectedColor: Colors.green,
                    notSelectedColor: Colors.red,
                    digitColor: Colors.white,
                    selectedDigitColor: Colors.yellowAccent,
                    onInputComplete: (input, points) async {
                      final canvasSize = [
                        constraints.maxWidth,
                        constraints.maxHeight
                      ];
                      print("pattern is $input");
                      setState(() {
                        pattern = input.join(" ");
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Uploading")));
                      final response = await utils.uploadPatternToAPI(
                          points, context, canvasSize);
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Pattern: $pattern',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
