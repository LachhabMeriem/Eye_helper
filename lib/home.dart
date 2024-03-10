import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:math' as math;
// import 'package:audioplayers/audioplayers.dart';

import 'camera.dart';
import 'bndbox.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage(this.cameras, {Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<HomePage> {
  late String _model;
  int _imageHeight = 0;
  int _imageWidth = 0;
  List<dynamic> _recognitions = [];

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      setState(() {
        _model = "yolo";
      });
    }).catchError((error) {
      print('Failed to load model: $error');
    });
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/models/yolov8n.tflite",
        labels: "assets/labels.txt",
      );
      print("Model loaded successfully");
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  void setRecognitions(List<dynamic> recognitions, int imageHeight, int imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Camera(widget.cameras, _model, setRecognitions),
          BndBox(
              _recognitions == null ? [] : _recognitions,
              math.max(_imageHeight, _imageWidth),
              math.min(_imageHeight, _imageWidth),
              screen.height,
              screen.width,
              _model
          ),
        ],
      ),
    );
  }
}
