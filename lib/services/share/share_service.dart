import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// The system share sheet (WhatsApp, Instagram, Messages…).
abstract class ShareService {
  Future<void> shareText(String text, {String? subject});
  Future<void> shareImage(Uint8List png, {required String name, String? text});
}

class SystemShareService implements ShareService {
  @override
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));

  @override
  Future<void> shareImage(Uint8List png, {required String name, String? text}) => SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
      text: text,
    ),
  );
}

/// Tests: remembers what would have been shared.
class RecordingShareService implements ShareService {
  final texts = <String>[];
  final images = <String>[];

  @override
  Future<void> shareText(String text, {String? subject}) async => texts.add(text);

  @override
  Future<void> shareImage(Uint8List png, {required String name, String? text}) async => images.add(name);
}
