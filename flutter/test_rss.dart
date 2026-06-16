import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.allorigins.win/get?url=${Uri.encodeComponent('https://www.cnbcindonesia.com/market/rss')}');
  try {
    print('Fetching from proxy...');
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['contents'];
      print('Content length: ${content.length}');
      print(content.substring(0, 200));
    }
  } catch (e) {
    print('Error: $e');
  }
}
