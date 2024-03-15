// import 'dart:math';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'object_detection.dart';
// import 'BoundingBox.dart' ;
//
//
// typedef void Callback(List<dynamic> list, int h, int w);
//
// class Camera extends StatefulWidget {
//   final List<CameraDescription> cameras;
//
//   Camera(this.cameras);
//
//   @override
//   _CameraState createState() => _CameraState();
// }
//
// class _CameraState extends State<Camera> {
//   late CameraController _controller;
//   bool _isDetecting = false;
//
//   ObjectDetection? objectDetection;
//
//   List<BoundingBox>? boxes;
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     objectDetection = ObjectDetection();
//     if (widget.cameras.isEmpty) {
//       print('No camera is found');
//     } else {
//       _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
//       _controller.initialize().then((_) {
//         if (!mounted) return;
//         setState(() {});
//         _controller.startImageStream((CameraImage image) {
//           if (_isDetecting) return;
//           _isDetecting = true;
//           int startTime = DateTime.now().millisecondsSinceEpoch;
//           try {
//             boxes = objectDetection!.analyseImage(image);
//           } catch (error) {
//             print("Error during object detection: $error");
//             _isDetecting = false;
//           } finally {
//             int endTime = DateTime
//                 .now()
//                 .millisecondsSinceEpoch;
//             print("Detection took ${endTime - startTime}");
//             _isDetecting = false;
//           }
//         });
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_controller.value.isInitialized) {
//       return Container();
//     }
//     var tmp = MediaQuery.of(context).size;
//     var screenH = max(tmp.height, tmp.width);
//     var screenW = min(tmp.height, tmp.width);
//     var previewSize = _controller.value.previewSize ?? Size(0, 0);
//     var previewH = max(previewSize.height, previewSize.width);
//     var previewW = min(previewSize.height, previewSize.width);
//     var screenRatio = screenH / screenW;
//     var previewRatio = previewH / previewW;
//
//     return OverflowBox(
//       maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
//       maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
//       child: CameraPreview(_controller),
//     );
//   }
//
// }
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'object_detection.dart';
import 'BoundingBox.dart';
import 'drawingboxes.dart';
import 'dart:math';

typedef void Callback(List<BoundingBox>? boundingboxes , int _screenHeight , int _screenWidth );

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;

  Camera(this.cameras, this.setRecognitions);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<Camera> {
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  ObjectDetection? objectDetection;
  List<BoundingBox>? boxes;
  static const String _labelPath = 'assets/labels.txt';
  bool _isDetecting = false;


  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
    if (widget.cameras.isEmpty) {
      print('No camera is found');
    } else {
      _cameraController = CameraController(widget.cameras[0], ResolutionPreset.high);
      _cameraController.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _cameraController.startImageStream((CameraImage image) {
          if (_isDetecting) return;
          _isDetecting = true;
          int startTime = DateTime.now().millisecondsSinceEpoch;
          try {
            boxes = objectDetection!.analyseImage(image);
            widget.setRecognitions(boxes,image.width,image.height);
            for (var box in boxes!){
              print(box.maxClsIdx);
            }
          } catch (error) {
            print("Error during object detection: $error");
            _isDetecting = false;
          } finally {
            int endTime = DateTime
                .now()
                .millisecondsSinceEpoch;
            print("Detection took ${endTime - startTime}");
            _isDetecting = false;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container();
    }
    var tmp = MediaQuery.of(context).size;
    var screenH = max(tmp.height, tmp.width);
    var screenW = min(tmp.height, tmp.width);
    var previewSize = _cameraController.value.previewSize ?? Size(0, 0);
    var previewH = max(previewSize.height, previewSize.width);
    var previewW = min(previewSize.height, previewSize.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(_cameraController),
    );
  }
}



