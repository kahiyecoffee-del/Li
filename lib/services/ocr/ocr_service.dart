/// On-device text recognition. Receipt images never leave the device; only
/// the extracted, user-confirmed values are saved.
abstract class OcrService {
  Future<String> recognize(String imagePath);
}

/// No text recognition available (e.g. simulator builds without ML Kit).
class NoOcrService implements OcrService {
  const NoOcrService();

  @override
  Future<String> recognize(String imagePath) async => '';
}
