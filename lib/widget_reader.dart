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
  String replyText = '';
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
    final XFile? result = await imagePicker.pickImage(source: ImageSource.camera);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
    await textRecognizer.processImage(InputImage.fromFilePath(result!.path));
    String parsedText = recognizedText.text.toString();
    await _sendDataToModel(parsedText);
  }

  Future<void> _sendDataToModel(String parsedText) async {
    try {
      HttpClient httpClient = HttpClient();
      const url = "https://a957-105-191-94-217.ngrok-free.app/api";
      Map data = {
        "text": parsedText,
      };
      HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(json.encode(data)));
      HttpClientResponse response = await request.close();
      String reply = await response.transform(utf8.decoder).join();
      httpClient.close();
      Map<String, dynamic> jsonResponse = json.decode(reply);
      String summary = jsonResponse["summary"];
      setState(() {
        replyText = summary;
      });

    } catch (e) {
      print('Failed to send data to the server: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Background color
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              child: Text(
                replyText,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
