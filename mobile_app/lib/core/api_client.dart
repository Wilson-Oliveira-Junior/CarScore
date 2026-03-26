import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({this.baseUrl = 'http://localhost:3333'});

  final String baseUrl;

  Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse('$baseUrl/health');
    final resp = await http.get(uri);
    return _parse(resp);
  }

  Future<Map<String, dynamic>> estimate(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/v1/analysis/estimate');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return _parse(resp);
  }

  Map<String, dynamic> _parse(http.Response resp) {
    final status = resp.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception('Request failed (${resp.statusCode}): ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
