import 'package:flutter/material.dart';
import 'BoundingBox.dart';

class BndBox extends StatelessWidget {
  final List<BoundingBox>? results;
  final int screenX;
  final int screenY;
  List<String>? _labels;
  final image;

  BndBox(this.results, this._labels, this.screenX, this.screenY, this.image);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoundingBoxPainter(results, screenX, screenY, _labels, image),
      child: Container(
        width: screenX.toDouble(),
        height: screenY.toDouble(),
        child: Image.memory(image),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBox>? results;
  final int screenX;
  final int screenY;
  final List<String>? labels;
  final image;

  BoundingBoxPainter(this.results, this.screenX, this.screenY, this.labels, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (results != null) {
      final double scaleX = size.width / screenX;
      final double scaleY = size.height / screenY;

      for (final box in results!) {
        final left = box.left * scaleX;
        final top = box.top * scaleY;
        final right = box.right * scaleX;
        final bottom = box.bottom * scaleY;
        final width = right - left;
        final height = bottom - top;

        final Paint paint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

        final textStyle = TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
        final textSpan = TextSpan(
          text: labels?[box.maxClsIdx] ?? 'Unknown',
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(left, top - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
