import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (Google ML Kit). Receipt images never leave the
/// device; only the extracted, user-confirmed values are saved.
abstract class OcrService {
  Future<String> recognize(String imagePath);
}

class MlKitOcrService implements OcrService {
  @override
  Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
