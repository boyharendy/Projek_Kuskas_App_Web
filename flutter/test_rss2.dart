import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fwww.cnbcindonesia.com%2Fmarket%2Frss');
  try {
    print('Fetching from rss2json...');
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Status API: ${jsonResponse['status']}');
      final items = jsonResponse['items'] as List;
      print('Found ${items.length} items.');
      if (items.isNotEmpty) {
        print('First item title: ${items[0]['title']}');
        print('First item link: ${items[0]['link']}');
      }
    } else {
      print('Failed: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
