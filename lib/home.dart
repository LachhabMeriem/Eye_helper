import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
// import 'package:audioplayers/audioplayers.dart';

import 'BoundingBox.dart';
import 'camera.dart';
import 'drawingboxes.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<HomePage> {
  static const String _labelPath = 'assets/labels.txt';
  List<String>? _labels;
  List<BoundingBox>? boxes;
  int _screenHeight = 0;
  int _screenWidth = 0;

  Future<void> _loadLabels() async {
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');
  }

  void setRecognitions(List<BoundingBox>? boundingboxes , int _screenHeight , int _screenWidth ) {
    setState(() {
      boxes = boundingboxes ;
      _screenHeight = _screenHeight;
      _screenWidth = _screenWidth;
    });
  }
  @override
  Widget build(BuildContext context) {
    _loadLabels();
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Camera(widget.cameras,setRecognitions),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: BndBox(boxes, _labels, _screenHeight, _screenWidth, ),

            ),
          ),
        ],
      ),
    );
  }

}
