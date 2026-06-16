import 'dart:io';

Future<void> saveAndDownloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final file = File(filename);
  await file.writeAsBytes(bytes);
}
