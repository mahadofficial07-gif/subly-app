import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// Handles saving/loading subscriptions to the device's local storage.
/// No server, no account, no internet connection required.
class StorageService {
  static const _storageKey = 'subly_subscriptions';
  static const _proKey = 'subly_is_pro';

  Future<bool> loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proKey) ?? false;
  }

  Future<void> saveProStatus(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, isPro);
  }

  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(subscriptions.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
