import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iitb_proj/utils.dart';

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

  /// Callback that called when user's input complete. Called if user selected one or more points.
  final Function(List<int>, List<Offset>) onInputComplete;

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
  List<int> randomPoints = [];
  List<Offset> points = [];
  Offset? currentPoint;
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
        final randomPointsUsed = [for (var i in used) randomPoints[i]];
        if (used.isNotEmpty) {
          widget.onInputComplete(randomPointsUsed, points);
        }
        setState(() {
          points = [];
          used = [];
          currentPoint = null;
        });
      },
      onPanEnd: (DragEndDetails details) {
        final randomPointsUsed = [for (var i in used) randomPoints[i]];
        if (used.isNotEmpty) {
          widget.onInputComplete(randomPointsUsed, points);
        }
        setState(() {
          points = [];
          used = [];
          currentPoint = null;
        });
      },
      onPanUpdate: (details) {
        points.add(details.localPosition);
        RenderBox referenceBox = context.findRenderObject() as RenderBox;
        Offset localPosition =
            referenceBox.globalToLocal(details.globalPosition);

        Offset circlePosition(int n) => utils.calcCirclePosition(
              n,
              referenceBox.size,
              widget.numberOfPoints,
              widget.relativePadding,
              widget.circleRadiusCoefficient,
            );

        setState(() {
          currentPoint = localPosition;
          for (int i = 0; i < widget.numberOfPoints; ++i) {
            final toPoint = (circlePosition(i) - localPosition).distance;
            if (!used.contains(i) && toPoint < widget.selectThreshold) {
              used.add(i);
            }
          }
        });
      },
      child: CustomPaint(
        painter: _LockPainter(
          randomPoints: randomPoints,
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
}

class _LockPainter extends CustomPainter {
  final List<int> randomPoints;
  final int numberOfPoints;
  final List<int> used;
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

  _LockPainter({
    required this.randomPoints,
    required this.numberOfPoints,
    required this.used,
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
    Offset circlePosition(int n) => utils.calcCirclePosition(
        n, size, numberOfPoints, relativePadding, circleRadiusCoefficient);

    for (int i = 0; i < min(numberOfPoints, randomPoints.length); ++i) {
      final int index = i;
      final bool isSelected = showInput && used.contains(index);

      // Draw the circle
      canvas.drawCircle(
        circlePosition(index),
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
          circlePosition(index).dx - pointRadius * 0.3,
          circlePosition(index).dy - pointRadius * 0.6,
        ),
      );
    }

    if (showInput) {
      for (int i = 0; i < used.length - 1; ++i) {
        canvas.drawLine(
          circlePosition(used[i]),
          circlePosition(used[i + 1]),
          selectedPaint,
        );
      }

      final currentPoint = this.currentPoint;
      if (used.isNotEmpty && currentPoint != null) {
        canvas.drawLine(
          circlePosition(used[used.length - 1]),
          currentPoint,
          selectedPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
