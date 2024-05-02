import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:eye_helper_project/main.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'BoundingBox.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

class ObjectDetection {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts flutterTts = FlutterTts();

  static const String _modelPath = 'assets/models/yolov8n.tflite';
  static const String _labelPath = 'assets/labels.txt';
  List<BoundingBox>? bestbox;
  Interpreter? _interpreter;
  List<String>? _labels;
  late final OriginalImage;
  late final ScreenX;
  late final ScreenY;

  ObjectDetection() {
    _loadModel();
    _loadLabels();
    log('Done.');

    // Initialiser le moteur de reconnaissance vocale
    _speech.initialize();
  }

  get getbestBoxes => bestbox;

  get Image => OriginalImage;

  get labels => _labels;

  get Width => ScreenX;

  get Height => ScreenY;

  Future<void> _loadModel() async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Utiliser le délégué XNNPACK
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Utiliser le délégué Metal
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

  Uint8List imageToByteListFloat32(img.Image image, int inputSize, double mean,
      double std) {
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

        // Le plan Y doit avoir des valeurs positives appartenant à [0...255]
        final int y = yBuffer[yIndex];

        final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 +
            44 -
            v * 93604 / 131072 +
            91)
            .round();
        int b = (y + u * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixelRgb(w, h, r, g, b);
      }
    }

    return image;
  }

  Future<void> analyseImage(final imagePath, BuildContext context) async {
    log('Analysing image...');

    // final image = convertYUV420ToImage(cameraImage);
    final imageData = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(imageData);
    ScreenX = image?.width;
    ScreenY = image?.height;
    print(ScreenX);
    print(ScreenY);
    final imageInput = img.copyResize(
      image!,
      width: 640,
      height: 640,
    );

    final imageMatrix = imageToByteListFloat32(
        imageInput, 640, INPUT_MEAN, INPUT_STANDARD_DEVIATION);

    final output = _runInference(imageMatrix);
    final DoubleOutput = output.flatten();
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

    // Récupération des noms des objets détectés
    List<String> detectedObjects = [];
    for (final box in bestbox!) {
      if (box.maxClsConfidence > 0.40) {
        detectedObjects.add(_labels?[box.maxClsIdx] ?? "Unknown");
      }
    }

    // Lecture des noms des objets détectés
    await readDetectedObjects(detectedObjects, context);
  }
  Future<void> readDetectedObjects(List<String> detectedObjects, BuildContext context) async {
    // Construire le texte à lire contenant les objets détectés et leur position
    String objectsText = "Objets détectés : ";
    for (int i = 0; i < detectedObjects.length; i++) {
      objectsText += detectedObjects[i];
      // Lire la position de l'objet
      objectsText += ", position : ${determinePosition(detectedObjects[i])}";
      if (i < detectedObjects.length - 1) {
        objectsText += ", ";
      }
    }

    // Lire le texte contenant les objets détectés et poser la question pour continuer
    await flutterTts.speak("$objectsText, voulez-vous continuer la détection des objets ?");
    await askToContinueDetection(context);
  }



  // Fonction pour déterminer la position de l'objet par rapport au centre de l'image
  String determinePosition(String objectName) {
    // Calculer la position de l'objet par rapport au centre de l'image
    double objectXPosition = getObjectXPosition(objectName, bestbox!);


    // Déterminer si l'objet est à gauche, à droite ou au centre en fonction de sa position horizontale
    if (objectXPosition < 0.25) {
      return "gauche";
    } else if (objectXPosition > 0.55) {
      return "droite";
    } else {
      return "Centre";
    }
  }

  // Fonction pour obtenir la position horizontale (x) de l'objet par rapport au centre de l'image
  double getObjectXPosition(String objectName, List<BoundingBox> detectedBoxes) {
    // Recherchez la boîte englobante de l'objet correspondant au nom donné
    BoundingBox? objectBox;
    for (BoundingBox box in detectedBoxes) {
      if (_labels?[box.maxClsIdx] == objectName) {
        objectBox = box;
        break;
      }
    }

    // Si la boîte de l'objet est trouvée, calculez sa position horizontale
    if (objectBox != null) {
      // Calculez le centre horizontal de la boîte englobante
      double boxCenterX = (objectBox.left + objectBox.right) / 2;

      // Normalisez la position horizontale par rapport à la largeur de l'image
      double normalizedXPosition = boxCenterX / ScreenX!;

      return normalizedXPosition;
    } else {
      // Si la boîte de l'objet n'est pas trouvée, retournez une valeur par défaut (au centre de l'image)
      return 0.5;
    }
  }


  Future<void> askToContinueDetection(BuildContext context) async {
    bool isListening = await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          // Convertir les mots reconnus en minuscules pour une comparaison insensible à la casse
          String recognizedWords = result.recognizedWords.toLowerCase();
          if (recognizedWords.contains('oui')) {
            // Redémarrer l'application
            restartApp(context);
          } else if (recognizedWords.contains('non')) {
            // Quitter l'application
            exit(0);
          } else {
            // Option non reconnue, répéter la question
            await flutterTts.speak("Je suis désolé, je n'ai pas compris. Voulez-vous continuer la détection d'objets ?");
            await askToContinueDetection(context);
          }
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );

    if (!isListening) {
      // Si la reconnaissance vocale n'est pas disponible, demander à nouveau
      await flutterTts.speak("Désolé, la reconnaissance vocale n'est pas disponible. Voulez-vous continuer la détection d'objets ?");
      await askToContinueDetection(context);
    }
  }

  List _runInference(final imageMatrix) {
    log('Running inference...');

    final input = imageMatrix;
    final output = List<num>.filled(1 * 84 * 8400, 0).reshape([1, 84, 8400]);
    _interpreter!.runForMultipleInputs([input.buffer], {0: output});
    return output;
  }

  List<BoundingBox>? bestBox(List<double> floatArray) {
    List<BoundingBox> boundingBoxes = [];
    for (int i = 0; i < NUM_ELEMENTS; i++) {
      double x = floatArray[i];
      double y = floatArray[NUM_ELEMENTS * 1 + i];
      double w = floatArray[NUM_ELEMENTS * 2 + i];
      double h = floatArray[NUM_ELEMENTS * 3 + i];
      double left = (x - (0.5 * w)); // x1
      double top = (y - (0.5 * y)); // y1
      double right = (x + (0.5 * w)); // x2
      double bottom = (y + (0.5 * y)); // y2
      double width = w;
      double height = h;
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
          right: right,
          bottom: bottom,
          width: width,
          height: height,
          maxClsConfidence: maxClsConfidence,
        ),
      );
    }
    if (boundingBoxes.isEmpty) return null;
    final result = applyNMS(boundingBoxes);
    return filtrerMaxConfidence(result!);
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

  List<BoundingBox> filtrerMaxConfidence(List<BoundingBox> boundingBoxes) {
    Map<int, BoundingBox> tempMap = {};
    for (var box in boundingBoxes) {
      if (!tempMap.containsKey(box.maxClsIdx)) {
        tempMap[box.maxClsIdx] = box;
      } else {
        if (box.maxClsConfidence > tempMap[box.maxClsIdx]!.maxClsConfidence) {
          tempMap[box.maxClsIdx] = box;
        }
      }
    }
    return tempMap.values.toList();
  }

  void dispose() {
    _interpreter?.close();
    bestbox = null;
    _labels = null;
    OriginalImage = null;
    ScreenX = null;
    ScreenY = null;
  }

  static int TENSOR_WIDTH = 640;
  static int TENSOR_HEIGHT = 640;
  static double TENSOR_WIDTH_FLOAT = TENSOR_WIDTH.toDouble();
  static double TENSOR_HEIGHT_FLOAT = TENSOR_HEIGHT.toDouble();
  static const double INPUT_MEAN = 0;
  static const double INPUT_STANDARD_DEVIATION = 255;
  static const int NUM_ELEMENTS = 8400;
  static const double CONFIDENCE_THRESHOLD = 0.5;
  static const double IOU_THRESHOLD = 0.5;

  // Fonction pour redémarrer l'application
  void restartApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyApp()),
    );
  }
}
