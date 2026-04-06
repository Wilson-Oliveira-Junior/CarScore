import 'dart:convert';
import 'package:http/http.dart' as http;

typedef ScoreWeights = Map<String, double>;

class FipeBrand {
  final String code;
  final String name;
  FipeBrand({required this.code, required this.name});
  factory FipeBrand.fromJson(Map<String, dynamic> j) =>
      FipeBrand(code: j['code'] as String, name: j['name'] as String);
}

class FipeModel {
  final int code;
  final String name;
  FipeModel({required this.code, required this.name});
  factory FipeModel.fromJson(Map<String, dynamic> j) =>
      FipeModel(code: j['code'] as int, name: j['name'] as String);
}

class FipeYear {
  final String code;
  final String name;
  FipeYear({required this.code, required this.name});
  factory FipeYear.fromJson(Map<String, dynamic> j) =>
      FipeYear(code: j['code'] as String, name: j['name'] as String);
}

class FipePrice {
  final double referencePrice;
  final String? referencePriceFormatted;
  final String brand;
  final String model;
  final int yearModel;
  final String fuel;
  final String? referenceMonth;
  final String source;
  final String sourceName;
  final bool isFallback;
  FipePrice({
    required this.referencePrice,
    this.referencePriceFormatted,
    required this.brand,
    required this.model,
    required this.yearModel,
    required this.fuel,
    this.referenceMonth,
    this.source = 'brasilapi',
    this.sourceName = 'BrasilAPI',
    this.isFallback = false,
  });
  factory FipePrice.fromJson(Map<String, dynamic> j) => FipePrice(
        referencePrice: (j['referencePrice'] as num).toDouble(),
        referencePriceFormatted: j['referencePriceFormatted'] as String?,
        brand: j['brand'] as String,
        model: j['model'] as String,
        yearModel: j['yearModel'] as int,
        fuel: j['fuel'] as String,
        referenceMonth: j['referenceMonth'] as String?,
        source: j['source'] as String? ?? 'brasilapi',
        sourceName: j['sourceName'] as String? ?? 'BrasilAPI',
        isFallback: j['isFallback'] as bool? ?? false,
      );
}

class VehicleConsumption {
  final double urbanKmL;
  final double roadKmL;
  final double averageKmL;
  final double? ethanolUrbanKmL;
  final double? ethanolRoadKmL;
  final double? ethanolAverageKmL;
  final String fuel;
  VehicleConsumption({
    required this.urbanKmL,
    required this.roadKmL,
    required this.averageKmL,
    this.ethanolUrbanKmL,
    this.ethanolRoadKmL,
    this.ethanolAverageKmL,
    required this.fuel,
  });
  factory VehicleConsumption.fromJson(Map<String, dynamic> j) {
    final c = j['consumption'] as Map<String, dynamic>;
    return VehicleConsumption(
      urbanKmL: (c['urbanKmL'] as num).toDouble(),
      roadKmL: (c['roadKmL'] as num).toDouble(),
      averageKmL: (c['averageKmL'] as num).toDouble(),
      ethanolUrbanKmL: c['ethanolUrbanKmL'] != null ? (c['ethanolUrbanKmL'] as num).toDouble() : null,
      ethanolRoadKmL: c['ethanolRoadKmL'] != null ? (c['ethanolRoadKmL'] as num).toDouble() : null,
      ethanolAverageKmL: c['ethanolAverageKmL'] != null ? (c['ethanolAverageKmL'] as num).toDouble() : null,
      fuel: j['fuel'] as String,
    );
  }
}

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:3333',
            );

  final String baseUrl;

  Future<Map<String, dynamic>> health() async {
    final uri = Uri.parse('$baseUrl/health');
    final resp = await http.get(uri);
    return _parse(resp);
  }

  Future<Map<String, dynamic>> estimate(Map<String, dynamic> body) async {
    final payload = Map<String, dynamic>.from(body);
    final uri = Uri.parse('$baseUrl/v1/analysis/estimate');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    return _parse(resp);
  }

  Future<Map<String, dynamic>> estimateWithParts({
    required Map<String, dynamic> analysis,
    required Map<String, dynamic> parts,
    String? clientId,
    Map<String, dynamic>? weights,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/analysis/estimate-with-parts');
    final body = <String, dynamic>{
      'analysis': analysis,
      'parts': parts,
    };
    if (weights != null) {
      body['weights'] = weights;
    }
    if (clientId != null && clientId.trim().isNotEmpty) {
      body['clientId'] = clientId.trim();
    }
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _parse(resp);
  }

  Future<Map<String, dynamic>> estimateParts(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl/v1/parts/estimate');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _parse(resp);
  }

  Future<List<Map<String, dynamic>>> history({int limit = 20, String? clientId}) async {
    final query = <String, String>{'limit': '$limit'};
    if (clientId != null && clientId.trim().isNotEmpty) {
      query['clientId'] = clientId.trim();
    }
    final uri = Uri.parse('$baseUrl/v1/analysis/history').replace(queryParameters: query);
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    final rawItems = (parsed['items'] as List<dynamic>? ?? []);
    return rawItems
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> clearHistory({String? clientId}) async {
    final query = <String, String>{};
    if (clientId != null && clientId.trim().isNotEmpty) {
      query['clientId'] = clientId.trim();
    }
    final uri = Uri.parse('$baseUrl/v1/analysis/history').replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final resp = await http.delete(uri);
    return _parse(resp);
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

  // ── Veículos ──────────────────────────────────────────────────────────────

  Future<List<FipeBrand>> getBrands() async {
    final uri = Uri.parse('$baseUrl/v1/vehicles/brands');
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    return (parsed['items'] as List<dynamic>)
        .map((e) => FipeBrand.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FipeModel>> getModels(String brandCode) async {
    final uri = Uri.parse('$baseUrl/v1/vehicles/models?brandCode=$brandCode');
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    return (parsed['items'] as List<dynamic>)
        .map((e) => FipeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FipeYear>> getYears(String brandCode, int modelCode) async {
    final uri = Uri.parse('$baseUrl/v1/vehicles/years?brandCode=$brandCode&modelCode=$modelCode');
    final resp = await http.get(uri);
    final parsed = _parse(resp);
    return (parsed['items'] as List<dynamic>)
        .map((e) => FipeYear.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FipePrice> getFipePrice(String brandCode, int modelCode, String yearCode) async {
    final uri = Uri.parse(
        '$baseUrl/v1/vehicles/fipe-price?brandCode=$brandCode&modelCode=$modelCode&yearCode=$yearCode');
    final resp = await http.get(uri);
    return FipePrice.fromJson(_parse(resp));
  }

  Future<VehicleConsumption?> getConsumption(String brand, String model, int year) async {
    final uri = Uri.parse(
        '$baseUrl/v1/vehicles/consumption?brand=${Uri.encodeComponent(brand)}&model=${Uri.encodeComponent(model)}&year=$year');
    final resp = await http.get(uri);
    if (resp.statusCode == 404) return null;
    return VehicleConsumption.fromJson(_parse(resp));
  }

  Map<String, dynamic> _parse(http.Response resp) {
    final status = resp.statusCode;
    if (status < 200 || status >= 300) {
      throw Exception('Request failed (${resp.statusCode}): ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}

// ── Marketplace ───────────────────────────────────────────────────────────────

class MarketplaceOffer {
  final String id;
  final String title;
  final double price;
  final double fipeEstimate;
  final double fipeDiff;
  final String thumbnailUrl;
  final String listingUrl;
  final String region;
  final String city;
  final int km;
  final String brand;
  final String model;
  final int year;
  final String source;
  final String sourceName;
  final int qualityScore;

  MarketplaceOffer({
    required this.id,
    required this.title,
    required this.price,
    required this.fipeEstimate,
    required this.fipeDiff,
    required this.thumbnailUrl,
    required this.listingUrl,
    required this.region,
    required this.city,
    required this.km,
    required this.brand,
    required this.model,
    required this.year,
    required this.source,
    required this.sourceName,
    this.qualityScore = 0,
  });

  factory MarketplaceOffer.fromJson(Map<String, dynamic> j) => MarketplaceOffer(
        id: j['id'] as String,
        title: j['title'] as String,
        price: (j['price'] as num).toDouble(),
        fipeEstimate: (j['fipeEstimate'] as num).toDouble(),
        fipeDiff: (j['fipeDiff'] as num).toDouble(),
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        listingUrl: j['listingUrl'] as String? ?? '',
        region: j['region'] as String? ?? '',
        city: j['city'] as String? ?? '',
        km: (j['km'] as num? ?? 0).toInt(),
        brand: j['brand'] as String? ?? '',
        model: j['model'] as String? ?? '',
        year: (j['year'] as num? ?? 0).toInt(),
        source: j['source'] as String? ?? 'mercadolivre',
        sourceName: j['sourceName'] as String? ?? 'Mercado Livre',
        qualityScore: (j['qualityScore'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'price': price,
        'fipeEstimate': fipeEstimate,
        'fipeDiff': fipeDiff,
        'thumbnailUrl': thumbnailUrl,
        'listingUrl': listingUrl,
        'region': region,
        'city': city,
        'km': km,
        'brand': brand,
        'model': model,
        'year': year,
        'source': source,
        'sourceName': sourceName,
        'qualityScore': qualityScore,
      };
}

class OfferProviderHealth {
  final String id;
  final String name;
  final bool healthy;
  final int latencyMs;
  final String? note;

  OfferProviderHealth({
    required this.id,
    required this.name,
    required this.healthy,
    required this.latencyMs,
    this.note,
  });

  factory OfferProviderHealth.fromJson(Map<String, dynamic> j) =>
      OfferProviderHealth(
        id: j['id'] as String,
        name: j['name'] as String,
        healthy: j['healthy'] as bool? ?? false,
        latencyMs: (j['latencyMs'] as num? ?? 0).toInt(),
        note: j['note'] as String?,
      );
}

extension ApiClientOffers on ApiClient {
  Future<List<MarketplaceOffer>> getOffers({
    String region = 'Sao Paulo',
    int limit = 12,
    String? brand,
    String? model,
    double? minPrice,
    double? maxPrice,
    int? maxKm,
    int? minYear,
    List<String>? providers,
  }) async {
    final queryParameters = <String, String>{
      'region': region,
      'limit': '$limit',
      if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (minPrice != null) 'minPrice': minPrice.round().toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.round().toString(),
      if (maxKm != null) 'maxKm': '$maxKm',
      if (minYear != null) 'minYear': '$minYear',
      if (providers != null && providers.isNotEmpty) 'providers': providers.join(','),
    };
    final uri = Uri.parse('$baseUrl/v1/offers').replace(queryParameters: queryParameters);
    final resp = await http.get(uri);
    final parsed = _parseOffers(resp);
    return (parsed['items'] as List<dynamic>)
        .map((e) => MarketplaceOffer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<OfferProviderHealth>> getOffersProvidersHealth() async {
    final uri = Uri.parse('$baseUrl/v1/offers/providers/health');
    final resp = await http.get(uri);
    final parsed = _parseOffers(resp);
    return (parsed['providers'] as List<dynamic>)
        .map((e) => OfferProviderHealth.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Map<String, dynamic> _parseOffers(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Offers request failed (${resp.statusCode})');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
