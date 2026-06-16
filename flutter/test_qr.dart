import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';

void main() {
  final decoder = QrCodeDartDecoder();
  print('Decoder instance: $decoder');
  // Check if we can find the methods or attributes of QrCodeDartDecoder via reflection or simply test compiling/running it.
  try {
    print('Checking methods...');
  } catch (e) {
    print('Error: $e');
  }
}
