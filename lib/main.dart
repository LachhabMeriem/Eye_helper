import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'object_detection.dart';
import 'dart:io' show Platform;
import 'BoundingBoxPage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),
      home: const MyHome(),
    );
  }
}

class MyHome extends StatefulWidget {
  const MyHome({Key? key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final imagePicker = ImagePicker();
  ObjectDetection? objectDetection;
  Uint8List? image;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _initSpeech();
      _speakInstruction();
    });
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print("La reconnaissance vocale n'est pas disponible.");
    } else {
      _speech.listen(
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          if (command.contains("ok")) {
            _flutterTts.speak("Lancement de la caméra.");
            _launchCamera();
          }
        },
      );
    }
  }

  Future<void> _launchCamera() async {
    final result = await imagePicker.pickImage(source: ImageSource.camera);
    if (result != null) {
      objectDetection!.analyseImage(result.path, context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BndBoxPage(
            objectDetection: objectDetection!,
          ),
        ),
      );
    }
  }

  Future<void> _speakInstruction() async {
    await _flutterTts.speak("Pour détecter un objet, dites 'ok'");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        centerTitle: true,
        backgroundColor: Colors.lightGreen.withOpacity(0.8),
      ),
      body: Center(
        child: IconButton(
          icon: const Icon(Icons.mic),
          iconSize: 60.0,
          color: Colors.lightGreen.withOpacity(0.8),
          onPressed: () {}, // Bouton inactif puisque la reconnaissance vocale est automatisée
        ),
      ),
    );
  }
}
