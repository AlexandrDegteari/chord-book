import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const _key = 'device_uuid';
  static String? _cachedUuid;

  static Future<String> getDeviceUuid() async {
    if (_cachedUuid != null) return _cachedUuid!;

    final prefs = await SharedPreferences.getInstance();
    var uuid = prefs.getString(_key);
    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString(_key, uuid);
    }
    _cachedUuid = uuid;
    return uuid;
  }
}
