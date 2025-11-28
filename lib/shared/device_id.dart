import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static const _key = 'eta_device_id';

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateId();
    await prefs.setString(_key, id);
    return id;
  }

  static String _generateId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(20, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
