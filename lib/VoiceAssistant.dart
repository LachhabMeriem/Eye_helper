import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts flutterTts = FlutterTts();

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<bool> listen({required Function(String) onResult}) async {
    return await _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords.toLowerCase());
        }
      },
    );
  }
}
