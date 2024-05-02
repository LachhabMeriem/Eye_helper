import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'BoundingBox.dart';

class BndBox extends StatelessWidget {
  final List<BoundingBox>? results;
  final List<String>? _labels;
  final int screenX;
  final int screenY;
  final Uint8List? image;

  BndBox(this.results, this._labels, this.screenX, this.screenY, this.image);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Image.memory(
              image!,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            CustomPaint(
              painter: BoundingBoxPainter(results, _labels, screenX, screenY),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          ],
        );
      },
    );
  }
}


class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBox>? results;
  final List<String>? labels;
  final int screenX;
  final int screenY;

  BoundingBoxPainter(this.results, this.labels, this.screenX, this.screenY);

  @override
void paint(Canvas canvas, Size size) {
    if (results != null) {
      final double scaleX = size.width / screenX;
      final double scaleY = size.height / screenY;

      for (int i = 0; i < results!.length; i++) {
        final box = results![i];
        final left = box.left ;
        final top = box.top ;
        final right = box.right * scaleX;
        final bottom = box.bottom * scaleY;
        final width = box.width;
        final height = box.height;

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
          text: '${labels?[box.maxClsIdx] ?? 'Unknown'}: ${box.maxClsConfidence.toStringAsFixed(2)}',
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final verticalPosition = top + (i * (textPainter.height + 5)); // Ajustez 5 selon l'espace souhaité entre les textes

        textPainter.paint(canvas, Offset(left, verticalPosition));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
