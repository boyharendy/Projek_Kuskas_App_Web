import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['models'] as List;
      print('Available models:');
      for (var model in models) {
        print('- \${model['name']} (supported methods: \${model['supportedGenerationMethods']})');
      }
    } else {
      print('Error \${response.statusCode}: \${response.body}');
    }
  } catch (e) {
    print('Failed: \$e');
  }
}
