import 'dart:developer';
import 'dart:io';
import 'dart:math' as math ;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'BoundingBox.dart' ;
import 'dart:typed_data' ;


class ObjectDetection {
  static const String _modelPath = 'assets/models/yolov8n.tflite';
  static const String _labelPath = 'assets/labels.txt';

  Interpreter? _interpreter;
  List<String>? _labels;

  ObjectDetection() {
    _loadModel();
    _loadLabels();
    log('Done.');
  }

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

  Uint8List imageToByteListFloat32( img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3 );
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getLuminance(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List analyseImage(String imagePath) {
    log('Analysing image...');
    // Reading image bytes from file
    final imageData = File(imagePath).readAsBytesSync();
    final Interpolation _interpolation = Interpolation.linear;
    // Decoding image
    final image = img.decodeImage(imageData);
    final imageInput = img.copyResize(
      image!,
      width: 640,
      height: 640,
    );
    final imageMatrix = imageToByteListFloat32(imageInput,TENSOR_WIDTH,INPUT_MEAN,INPUT_STANDARD_DEVIATION);
    print(imageMatrix);

    // Creating matrix representation, [300, 300, 3]
    // final imageMatrix = List.generate(
    //   imageInput.height,
    //       (y) => List.generate(
    //     imageInput.width,
    //         (x) {
    //       final pixel = imageInput.getPixel(x, y);
    //       return [pixel.r, pixel.g, pixel.b];
    //     },
    //   ),
    // );
    // final input = normalizeImage(imageMatrix);

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
    final bestBoxes = bestBox(floatArray) ;
    // print(bestBoxes);


    // final boxesTensor = output.map((e) => e.sublist(0,4)).toList();
    // final scoresTensor = output.map((e) => e.sublist(4,5)).toList();
    // final classesTensor = output.map((e) => e.sublist(5)).toList();
    //
    // // Process bounding boxes
    // final List locations = boxesTensor
    //     .map((box) => box.map((value) => ((value * 300).toInt())).toList())
    //     .toList();
    //
    // // Convert class indices to int
    // final classes = classesTensor.map((value) => value.toInt()).toList();
    //
    // // Number of detections
    // final numberOfDetections = output[2].first as double;
    //
    // // Get classifcation with label
    // final List<String> classification = [];
    // for (int i = 0; i < numberOfDetections; i++) {
    //   classification.add(_labels![classes[i]]);
    // }
    //
    // log('Outlining objects...');
    // for (var i = 0; i < numberOfDetections; i++) {
    //   if (scoresTensor[i] > 0.85) {
    //     // Rectangle drawing
    //     img.drawRect(
    //       imageInput,
    //       x1: locations[i][1],
    //       y1: locations[i][0],
    //       x2: locations[i][3],
    //       y2: locations[i][2],
    //       color: img.ColorRgb8(0, 255, 0),
    //       thickness: 3,
    //     );
    //
    //     // Label drawing
    //     img.drawString(
    //       imageInput,
    //       '${classification[i]} ${scoresTensor[i]}',
    //       font: img.arial14,
    //       x: locations[i][1] + 7,
    //       y: locations[i][0] + 7,
    //       color: img.ColorRgb8(0, 255, 0),
    //     );
    //   }
    // }

    log('Done.');
    return img.encodeJpg(imageInput);
  }

  List _runInference(
      final imageMatrix,
      ) {
    log('Running inference...');

    final input = imageMatrix;
    final output = List<num>.filled(1 * 84 * 8400, 0).reshape([1, 84, 8400]);
    _interpreter!.runForMultipleInputs([input], {0: output }) ;
    return output;
  }
  List<BoundingBox>? bestBox(Float32List array) {
    List<BoundingBox> boundingBoxes = [];
    for (int c = 0; c < NUM_ELEMENTS; c++) {
      double cnf = array[c + NUM_ELEMENTS * 4];
      print(cnf);
      if (cnf > CONFIDENCE_THRESHOLD) {
        double cx = array[c];
        double cy = array[c + NUM_ELEMENTS];
        double w = array[c + NUM_ELEMENTS * 2];
        double h = array[c + NUM_ELEMENTS * 3];
        double x1 = cx - (w / 2);
        double y1 = cy - (h / 2);
        double x2 = cx + (w / 2);
        double y2 = cy + (h / 2);
        if (x1 <= 0 || x1 >= TENSOR_WIDTH_FLOAT) continue;
        if (y1 <= 0 || y1 >= TENSOR_HEIGHT_FLOAT) continue;
        if (x2 <= 0 || x2 >= TENSOR_WIDTH_FLOAT) continue;
        if (y2 <= 0 || y2 >= TENSOR_HEIGHT_FLOAT) continue;
        boundingBoxes.add(
          BoundingBox(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            cx: cx,
            cy: cy,
            w: w,
            h: h,
            cnf: cnf,
          ),
        );
      }
    }
    if (boundingBoxes.isEmpty) return null;
    print(boundingBoxes);
    return applyNMS(boundingBoxes);
  }

  double calculateIoU(BoundingBox box1, BoundingBox box2) {
    double x1 = math.max(box1.x1, box2.x1);
    double y1 = math.max(box1.y1, box2.y1);
    double x2 = math.min(box1.x2, box2.x2);
    double y2 = math.min(box1.y2, box2.y2);
    double intersectionArea = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    double box1Area = box1.w * box1.h;
    double box2Area = box2.w * box2.h;
    return intersectionArea / (box1Area + box2Area - intersectionArea);
  }

  List<BoundingBox> applyNMS(List<BoundingBox> boxes) {
    List<BoundingBox> sortedBoxes = List.from(boxes)
      ..sort((a, b) => (b.w * b.h).compareTo(a.w * a.h));
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
