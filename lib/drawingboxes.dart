import 'package:flutter/material.dart';
import 'BoundingBox.dart';

class BndBox extends StatelessWidget {
  final List<BoundingBox>? results;
  final int screenX;
  final int screenY;
  List<String>? _labels;

  BndBox(this.results, this._labels, this.screenX, this.screenY);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBoxes() {
      return results?.map((re) {
        var left = re.left * (screenX / 640);
        var top = re.top * (screenY / 640);
        var right = re.right * (screenX / 640);
        var bottom = re.bottom * (screenY / 640);
        if (_labels?[re.maxClsIdx] != null && re.maxClsConfidence > 0.85) {
          return Positioned(
            left: left,
            top: top,
            child: Container(
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromRGBO(37, 213, 253, 1.0),
                  width: 3.0,
                ),
              ),
              child: Text(
                "${_labels?[re.maxClsIdx]} ${(re.maxClsConfidence * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: Color.fromRGBO(37, 213, 253, 1.0),
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      }).toList() ?? [];
    }

    return Stack(
      children: _renderBoxes(),
    );
  }
}
