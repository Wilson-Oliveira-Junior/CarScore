import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class ClientIdentity {
  static const _clientIdKey = 'carscore_client_id_v1';

  static Future<String> getOrCreateId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_clientIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final created = _generateId();
    await prefs.setString(_clientIdKey, created);
    return created;
  }

  static String _generateId() {
    final random = Random.secure();
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = List.generate(12, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'client-$now-$rand';
  }
}
