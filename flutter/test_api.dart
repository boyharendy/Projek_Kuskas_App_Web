import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List;
      print('=== BERHASIL KONEK KE GEMINI ===');
      print('Model yang tersedia untuk API Key ini:');
      for (var m in models) {
        print('- ' + m["name"].toString());
      }
    } else {
      print('ERROR ' + response.statusCode.toString() + ': ' + response.body);
    }
  } catch (e) {
    print('GAGAL: ' + e.toString());
  }
}
