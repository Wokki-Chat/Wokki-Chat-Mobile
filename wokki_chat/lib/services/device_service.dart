import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class DeviceService {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final stored = await _storage.read(key: _deviceIdKey);
    if (stored != null) {
      _cachedDeviceId = stored;
      return stored;
    }

    final id = _generateDeviceId();
    await _storage.write(key: _deviceIdKey, value: id);
    _cachedDeviceId = id;
    return id;
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}