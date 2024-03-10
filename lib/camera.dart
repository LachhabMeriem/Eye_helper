import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;

  Camera(this.cameras, this.model, this.setRecognitions);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController _controller;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      print('No camera is found');
    } else {
      _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
      _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.startImageStream((CameraImage image) {
          if (!_isDetecting) {
            _isDetecting = true;
            int startTime = DateTime.now().millisecondsSinceEpoch;
            Tflite.detectObjectOnFrame(
              bytesList: image.planes.map((plane) => plane.bytes).toList(),
              model: widget.model,
              imageHeight: image.height,
              imageWidth: image.width,
              imageMean: 0,
              imageStd: 255.0,
              numResultsPerClass: 1,
              threshold: 0.2,
            ).then((recognitions) {
              int endTime = DateTime.now().millisecondsSinceEpoch;
              print("Detection took ${endTime - startTime}");
              widget.setRecognitions(recognitions!, image.height, image.width);
              _isDetecting = false;
            }).catchError((error) {
              print('Failed to detect objects: $error');
              _isDetecting = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }
    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    var previewSize = _controller.value.previewSize ?? Size(0, 0);
    var previewH = math.max(previewSize.height, previewSize.width);
    var previewW = math.min(previewSize.height, previewSize.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(_controller),
    );
  }
}
