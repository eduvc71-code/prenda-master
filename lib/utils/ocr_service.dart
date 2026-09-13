import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);
    
    print('=== RAW OCR RECOGNIZED TEXT ===');
    print(recognizedText.text);
    print('===============================');
    
    return recognizedText.text;
  }

  Uint8List preprocessImage(Uint8List imageBytes) {
    return imageBytes;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
