import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'object_detection.dart';
import 'dart:io' show Platform;
import 'BoundingBoxPage.dart';

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

  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
    _startListening();
  }

  Future<void> _startListening() async {
    // Ici, vous pouvez démarrer l'écoute du texte à l'aide de la bibliothèque de reconnaissance vocale.
    // Par exemple, vous pouvez utiliser la bibliothèque 'speech_to_text' ou 'flutter_tts'.
    // Une fois que le texte est détecté, appelez _handleSpeechCommand avec le texte détecté.
    // Exemple: _handleSpeechCommand('1');
  }

  Future<void> _handleSpeechCommand(String command) async {
    if (command.toLowerCase() == '1') {
      // Lancer la capture d'image et la détection d'objets
      await _launchCameraAndDetectObjects();
    } else if (command.toLowerCase() == '2') {
      // Accéder à la fonctionnalité de scanner le texte à partir d'une image
      // Exemple : await _scanTextFromImage();
    } else if (command.toLowerCase() == '3') {
      // Quitter l'application
      // Exemple : await _exitApp();
    } else {
      // Option non reconnue, demander à nouveau
      await _startListening();
    }
  }

  Future<void> _launchCameraAndDetectObjects() async {
    final result = await imagePicker.pickImage(source: ImageSource.camera);
    if (result != null) {
      await objectDetection!.analyseImage(result.path, context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
