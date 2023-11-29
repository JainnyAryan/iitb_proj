import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iitb_proj/utils/utils.dart';

class CustomPatternLock extends StatefulWidget {
  /// Count of points horizontally and vertically.
  final int numberOfPoints;

  /// Padding of points area relative to distance between points.
  final double relativePadding;

  final Color digitColor;
  final Color selectedDigitColor;

  /// Color of selected points.
  final Color? selectedColor;

  /// Color of not selected points.
  final Color notSelectedColor;

  /// Radius of points.
  final double pointRadius;

  /// Radius of full circle
  final double circleRadiusCoefficient;

  /// Whether show user's input and highlight selected points.
  final bool showInput;

  // Needed distance from input to point to select point.
  final int selectThreshold;

  // Whether fill points.
  final bool fillPoints;

  static List cosSinData = [];

  /// Callback that called when user's input complete. Called if user selected one or more points.
  final Function(List<int>, List<Offset>, List<int>, List<double>, int, Map,
      List, Map<int, Offset>) onInputComplete;

  /// Creates [CustomPatternLock] with given params.
  const CustomPatternLock({
    Key? key,
    this.circleRadiusCoefficient = 1,
    this.digitColor = Colors.black,
    this.selectedDigitColor = Colors.white,
    this.numberOfPoints = 3,
    this.relativePadding = 0.7,
    this.selectedColor, // Theme.of(context).primaryColor if null
    this.notSelectedColor = Colors.black45,
    this.pointRadius = 10,
    this.showInput = true,
    this.selectThreshold = 25,
    this.fillPoints = false,
    required this.onInputComplete,
  }) : super(key: key);

  @override
  _CustomPatternLockState createState() => _CustomPatternLockState();
}

class _CustomPatternLockState extends State<CustomPatternLock> {
  List<int> used = [];
  List<Offset> usedPoints = [];
  List<int> randomPoints = [];
  List<Offset> points = [];
  Map<int, Offset> randomPointsPositions = {};
  int duration = 0;
  List<int> times = [];
  List<double> distances = [];
  DateTime? startTime;
  DateTime? currentStartTime;
  Offset? currentPoint;

  List jitterCsvData = [];

  Utils utils = Utils();


  @override
  void initState() {
    super.initState();
    randomPoints = List.generate(widget.numberOfPoints, (index) => index + 1);
    randomPoints.shuffle();
    print(randomPoints);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        times.clear();
        distances.clear();
        startRecording();
      },
      onPanEnd: (details) {
        // print("Positions : $randomPointsPositions");
        final randomPointsUsed = [for (var i in used) randomPoints[i]];
        if (used.isNotEmpty) {
          stopRecording();
          widget.onInputComplete(
              randomPointsUsed,
              points,
              times,
              distances,
              duration,
              utils.getJitterInfo(points),
              jitterCsvData,
              randomPointsPositions);
        }
        // for (var data in jitterCsvData) print(data);
        setState(() {
          usedPoints = [];
          points = [];
          used = [];
          jitterCsvData = [];
          currentPoint = null;
        });
      },
      onPanUpdate: (details) {
        points.add(details.localPosition);
        usedPoints.add(details.localPosition);
        RenderBox referenceBox = context.findRenderObject() as RenderBox;
        Offset localPosition =
            referenceBox.globalToLocal(details.globalPosition);

        Offset circlePosition(int n) => utils.calcCirclePosition(
              n,
              referenceBox.size,
              widget.numberOfPoints,
              widget.relativePadding,
              widget.circleRadiusCoefficient,
            )[0];

        if (used.length > 1 && usedPoints.isNotEmpty) {
          int digit1 = randomPoints[used[used.length - 2]];
          int digit2 = randomPoints[used[used.length - 1]];
          final jitterInfo = utils.getJitterInfo(usedPoints);
          jitterCsvData.add([
            GetStorage().read("parkinsonUserDetails")["name"],
            GetStorage().read("parkinsonUserDetails")["number"],
            digit1,
            digit2,
            jitterInfo["maxJitter"],
            jitterInfo["avgJitter"]
          ]);
        }

        setState(() {
          currentPoint = localPosition;
          for (int i = 0; i < widget.numberOfPoints; ++i) {
            final toPoint = (circlePosition(i) - localPosition).distance;
            if (!used.contains(i) && toPoint < widget.selectThreshold) {
              points.add(details.localPosition);
              used.add(i);
              usedPoints = [];
              if (used.length > 1) {
                final endTime = DateTime.now();
                final elapsedTime =
                    endTime.difference(currentStartTime!).inMilliseconds;
                times.add(elapsedTime);
                currentStartTime = DateTime.now();
              }
            }
          }
        });
      },
      child: CustomPaint(
        painter: LockPainter(
          randomPoints: randomPoints,
          randomPointsPositions: randomPointsPositions,
          numberOfPoints: widget.numberOfPoints,
          used: used,
          currentPoint: currentPoint,
          digitColor: widget.digitColor,
          selectedDigitColor: widget.selectedDigitColor,
          circleRadiusCoefficient: widget.circleRadiusCoefficient,
          relativePadding: widget.relativePadding,
          selectedColor: widget.selectedColor ?? Theme.of(context).primaryColor,
          notSelectedColor: widget.notSelectedColor,
          pointRadius: widget.pointRadius,
          showInput: widget.showInput,
          fillPoints: widget.fillPoints,
        ),
        size: Size.infinite,
      ),
    );
  }

  void startRecording() {
    startTime = DateTime.now();
    currentStartTime = DateTime.now();
  }

  void stopRecording() {
    if (startTime != null && used.length >= 2) {
      DateTime endTime = DateTime.now();
      for (int i = 0; i < used.length - 1; ++i) {
        int digit1 = randomPoints[used[i]];
        int digit2 = randomPoints[used[i + 1]];
        double euclideanDistance =
            (randomPointsPositions[digit2]! - randomPointsPositions[digit1]!)
                .distance; // Calculate distance
        distances.add(euclideanDistance);
      }
      endTime = DateTime.now();
      duration = endTime.difference(startTime!).inMilliseconds;
      startTime = null;
    }
    print(utils.getJitterInfo(points));
  }
}

class LockPainter extends CustomPainter {
  final List<int> randomPoints;
  final int numberOfPoints;
  final List<int> used;
  final Map<int, Offset> randomPointsPositions;
  final Offset? currentPoint;
  final double relativePadding;
  final double pointRadius;
  final bool showInput;
  final Color digitColor;
  final Color selectedDigitColor;
  final double circleRadiusCoefficient;
  final Paint circlePaint;
  final Paint selectedPaint;

  Utils utils = Utils();

  LockPainter({
    required this.randomPoints,
    required this.numberOfPoints,
    required this.used,
    required this.randomPointsPositions,
    this.currentPoint,
    this.digitColor = Colors.black,
    this.selectedDigitColor = Colors.white,
    this.circleRadiusCoefficient = 1,
    required this.relativePadding,
    required Color selectedColor,
    required Color notSelectedColor,
    required this.pointRadius,
    required this.showInput,
    required bool fillPoints,
  })  : circlePaint = Paint()
          ..color = notSelectedColor
          ..style = fillPoints ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2,
        selectedPaint = Paint()
          ..color = selectedColor
          ..style = fillPoints ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = pointRadius * 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    List circlePosition(int n) => utils.calcCirclePosition(
        n, size, numberOfPoints, relativePadding, circleRadiusCoefficient);

    for (int i = 0; i < min(numberOfPoints, randomPoints.length); ++i) {
      final int index = i;
      final bool isSelected = showInput && used.contains(index);

      randomPointsPositions[randomPoints[index]] = circlePosition(index)[0];
      CustomPatternLock.cosSinData.add(circlePosition(index)[1]);

      // Draw the circle
      canvas.drawCircle(
        circlePosition(index)[0],
        pointRadius,
        isSelected ? selectedPaint : circlePaint,
      );

      // Draw the digit inside the circle
      final textPainter = TextPainter(
        text: TextSpan(
          text: randomPoints[index].toString(),
          style: TextStyle(
            color: isSelected ? selectedDigitColor : digitColor,
            fontSize: pointRadius * 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: pointRadius * 2);
      textPainter.paint(
        canvas,
        Offset(
          circlePosition(index)[0].dx - pointRadius * 0.3,
          circlePosition(index)[0].dy - pointRadius * 0.6,
        ),
      );
    }

    if (showInput) {
      for (int i = 0; i < used.length - 1; ++i) {
        canvas.drawLine(
          circlePosition(used[i])[0],
          circlePosition(used[i + 1])[0],
          selectedPaint,
        );
      }

      final currentPoint = this.currentPoint;
      if (used.isNotEmpty && currentPoint != null) {
        canvas.drawLine(
          circlePosition(used[used.length - 1])[0],
          currentPoint,
          selectedPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
