import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';


void main() => runApp(const ReaderWidget());

class ReaderWidget extends StatelessWidget {
  const ReaderWidget({Key? key});

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
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final String _ocrApiKey = "K88476900388957";
  final String _ocrApiUrl = "https://api.ocr.space/parse/image";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
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
            _flutterTts.speak("Lancement de la caméra.");
            _launchCamera();
          
        },
      );
    }
  }

  Future<void> _launchCamera() async {
    final XFile? result = await _imagePicker.pickImage(source: ImageSource.camera);
    if (result!=null){
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
    await textRecognizer.processImage(InputImage.fromFilePath(result!.path));
    String parsedText = recognizedText.text.toString();
    print(parsedText);
    _sendDataToModel(parsedText);
    

  }}

  Future<void> _sendDataToModel(String parsedText) async {
    try {
      var url = Uri.parse('http://127.0.0.1:5000/api');
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': parsedText,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var result = responseData['result'];
        print('Result from server: $result');
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to send data to the server: $e');
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