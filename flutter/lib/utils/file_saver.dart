import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  /// Saves bytes as a downloadable file on the device
  static Future<void> saveAndDownload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    await saveAndDownloadFile(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }
}
