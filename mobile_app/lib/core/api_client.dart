import 'dart:convert';
import 'package:http/http.dart' as http;

typedef ScoreWeights = Map<String, double>;

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

  Future<List<Map<String, dynamic>>> history({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/v1/analysis/history?limit=$limit');
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    final rawItems = (parsed['items'] as List<dynamic>? ?? []);
    return rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<ScoreWeights> getWeights() async {
    final uri = Uri.parse('$baseUrl/v1/config/weights');
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    final raw = Map<String, dynamic>.from(parsed['weights'] as Map);
    return {
      'price': (raw['price'] as num).toDouble(),
      'fuel': (raw['fuel'] as num).toDouble(),
      'maintenance': (raw['maintenance'] as num).toDouble(),
      'adequacy': (raw['adequacy'] as num).toDouble(),
    };
  }

  Future<ScoreWeights> updateWeights(ScoreWeights weights) async {
    final uri = Uri.parse('$baseUrl/v1/config/weights');
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(weights),
    );
    final parsed = _parse(resp);
    final raw = Map<String, dynamic>.from(parsed['weights'] as Map);
    return {
      'price': (raw['price'] as num).toDouble(),
      'fuel': (raw['fuel'] as num).toDouble(),
      'maintenance': (raw['maintenance'] as num).toDouble(),
      'adequacy': (raw['adequacy'] as num).toDouble(),
    };
  }

  Map<String, dynamic> _parse(http.Response resp) {
    final status = resp.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception('Request failed (${resp.statusCode}): ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
