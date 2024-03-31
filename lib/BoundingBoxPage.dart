import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'drawingboxes.dart';
import 'object_detection.dart';

class BndBoxPage extends StatelessWidget {
  final ObjectDetection objectDetection;

  const BndBoxPage({Key? key, required this.objectDetection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BndBox(
          objectDetection.getbestBoxes,
          objectDetection.labels,
          objectDetection.Width,
          objectDetection.Height,
          objectDetection.OriginalImage!,
        ),
      ),
    );
  }
}