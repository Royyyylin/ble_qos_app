import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure PIN storage using platform keystore — spec §5.
/// iOS: Keychain, Android: EncryptedSharedPreferences.
class PinStorage {
  static const _storage = FlutterSecureStorage();
  static const _maintenancePinKey = 'auth_pin_maintenance';
  static const _engineerPinKey = 'auth_pin_engineer';

  static Future<void> saveMaintenancePin(String pin) =>
      _storage.write(key: _maintenancePinKey, value: pin);

  static Future<String?> readMaintenancePin() =>
      _storage.read(key: _maintenancePinKey);

  static Future<void> saveEngineerPin(String pin) =>
      _storage.write(key: _engineerPinKey, value: pin);

  static Future<String?> readEngineerPin() =>
      _storage.read(key: _engineerPinKey);

  static Future<void> clearAll() async {
    await _storage.delete(key: _maintenancePinKey);
    await _storage.delete(key: _engineerPinKey);
  }
}
