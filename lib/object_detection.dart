import 'dart:developer';
import 'dart:io';
import 'dart:math' as math ;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:tflite_flutter/tflite_flutter.dart';
import 'BoundingBox.dart' ;
import 'dart:typed_data' ;

import 'drawingboxes.dart';


class ObjectDetection {
  static const String _modelPath = 'assets/models/yolov8n.tflite';
  static const String _labelPath = 'assets/labels.txt';
  List<BoundingBox>? bestbox;
  Interpreter? _interpreter;
  List<String>? _labels;

  late final OriginalImage ;
  late final width ;
  late final height ;

  ObjectDetection() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

  get getbestBoxes => bestbox;
  get Image => OriginalImage;
  get labels => _labels ;
  get Width => width;
  get Height => height;


  Future<void> _loadModel() async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    log('Loading interpreter...');
    _interpreter =
    await Interpreter.fromAsset(_modelPath, options: interpreterOptions);
  }

  Future<void> _loadLabels() async {
    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(_labelPath);
    _labels = labelsRaw.split('\n');

  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final imageWidth = cameraImage.width;
    final imageHeight = cameraImage.height;

    final yBuffer = cameraImage.planes[0].bytes;
    final uBuffer = cameraImage.planes[1].bytes;
    final vBuffer = cameraImage.planes[2].bytes;

    final int yRowStride = cameraImage.planes[0].bytesPerRow;
    final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: imageWidth, height: imageHeight);

    for (int h = 0; h < imageHeight; h++) {
      int uvh = (h / 2).floor();

      for (int w = 0; w < imageWidth; w++) {
        int uvw = (w / 2).floor();

        final yIndex = (h * yRowStride) + (w * yPixelStride);

        // Y plane should have positive values belonging to [0...255]
        final int y = yBuffer[yIndex];

        final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
        int b = (y + u * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixelRgb(w, h, r, g, b);
      }
    }

    return image;
  }

  void analyseImage(final imagePath)  {
    log('Analysing image...');

    // final image = convertYUV420ToImage(cameraImage);
    final imageData = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(imageData);
    width = image?.width ;
    height = image?.height ;
    final imageInput = img.copyResize(
      image! ,
      width: 640,
      height: 640,
    );

    final imageMatrix = imageToByteListFloat32(imageInput, 640, INPUT_MEAN,INPUT_STANDARD_DEVIATION);

    final output = _runInference(imageMatrix) ;
    final DoubleOutput = output.flatten() ;
    List<double> floatList = DoubleOutput.map((value) {
      if (value is double) {
        return value;
      } else if (value is int) {
        return value.toDouble();
      } else {
        throw ArgumentError("Value $value is not a double or int.");
      }
    }).toList();
    Float32List floatArray = Float32List.fromList(floatList);
    bestbox = bestBox(floatArray);
    OriginalImage = img.encodeJpg(image);
    log('Done.');
    for (final box in bestbox!){
      print(_labels?[box.maxClsIdx]);
    }
    // return img.encodeJpg(image);
    // return bestbox ;
  }

  List _runInference(final imageMatrix,) {
    log('Running inference...');

    final input = imageMatrix;
    final output = List<num>.filled(1 * 84 * 8400, 0).reshape([1, 84, 8400]);
    _interpreter!.runForMultipleInputs( [input.buffer] , {0: output }) ;
    return output;
  }

  List<BoundingBox>? bestBox(List<double> floatArray) {
    List<BoundingBox> boundingBoxes = [];
    for (int i = 0; i < NUM_ELEMENTS; i++) {
      double x = floatArray[i];
      double y = floatArray[NUM_ELEMENTS * 1 + i];
      double w = floatArray[NUM_ELEMENTS * 2 + i];
      double h = floatArray[NUM_ELEMENTS * 3 + i];
      double left = (x - (0.5 * w)) ;   // x1
      double top = (y - (0.5 * y)) ; // y1
      double right = (x + (0.5 * w) ) ; // x2
      double bottom =  (y + (0.5 * y)) ; // y2
      double width = w ;
      double height = h ;
      List<double> cls_confidences = [];
      for (int j = 0; j < 80; j++) {
        cls_confidences.add(floatArray[NUM_ELEMENTS * (4 + j) + i]);
      }
      int maxClsIdx = cls_confidences.indexOf(cls_confidences.reduce(math.max));
      double maxClsConfidence = cls_confidences[maxClsIdx];
      if (maxClsConfidence < 0.2) {
        continue;
      }
      boundingBoxes.add(
        BoundingBox(
          maxClsIdx: maxClsIdx,
          left: left,
          top: top,
          right : right ,
          bottom: bottom ,
          width: width,
          height: height,
          maxClsConfidence: maxClsConfidence,
        ),
      );
    }
    if (boundingBoxes.isEmpty) return null;
    return applyNMS(boundingBoxes);
  }

  double calculateIoU(BoundingBox box1, BoundingBox box2) {
    double x1 = math.max(box1.left, box2.left);
    double y1 = math.max(box1.top, box2.top);
    double x2 = math.min(box1.right, box2.right);
    double y2 = math.min(box1.bottom, box2.bottom);
    double intersectionArea = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    double box1Area = box1.width * box1.height;
    double box2Area = box2.width * box2.height;
    return intersectionArea / (box1Area + box2Area - intersectionArea);
  }

  List<BoundingBox>? applyNMS(List<BoundingBox> boxes) {
    List<BoundingBox> sortedBoxes = List.from(boxes)
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    List<BoundingBox> selectedBoxes = [];
    while (sortedBoxes.isNotEmpty) {
      BoundingBox first = sortedBoxes.first;
      selectedBoxes.add(first);
      sortedBoxes.remove(first);
      for (int i = 0; i < sortedBoxes.length; i++) {
        BoundingBox nextBox = sortedBoxes[i];
        double iou = calculateIoU(first, nextBox);
        if (iou >= IOU_THRESHOLD) {
          sortedBoxes.removeAt(i);
          i--;
        }
      }
    }
    return selectedBoxes;
  }

  static  int TENSOR_WIDTH = 640;
  static  int TENSOR_HEIGHT = 640;
  static  double TENSOR_WIDTH_FLOAT = TENSOR_WIDTH.toDouble();
  static  double TENSOR_HEIGHT_FLOAT = TENSOR_HEIGHT.toDouble();
  static const double INPUT_MEAN = 0;
  static const double INPUT_STANDARD_DEVIATION = 255;
  static const int NUM_ELEMENTS = 8400;
  static const double CONFIDENCE_THRESHOLD = 0.5;
  static const double IOU_THRESHOLD = 0.5;


}
