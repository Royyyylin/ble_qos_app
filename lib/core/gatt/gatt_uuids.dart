/// GATT UUID constants matching firmware qos_service.h
/// Source of truth: docs/current/gatt_services.md
class GattUuids {
  GattUuids._();

  // Service
  static const serviceQos = '00001820-0000-1000-8000-00805f9b34fb';

  // Standard characteristics (0x2Axx)
  static const rssi = '00002a1c-0000-1000-8000-00805f9b34fb';
  static const status = '00002a1d-0000-1000-8000-00805f9b34fb';
  static const mode = '00002a1e-0000-1000-8000-00805f9b34fb';
  static const role = '00002a1f-0000-1000-8000-00805f9b34fb';
  static const cmd = '00002a20-0000-1000-8000-00805f9b34fb';
  static const ctrl = '00002a21-0000-1000-8000-00805f9b34fb';
  static const tp = '00002a22-0000-1000-8000-00805f9b34fb';
  static const metricsV2 = '00002a23-0000-1000-8000-00805f9b34fb';
  static const ping = '00002a24-0000-1000-8000-00805f9b34fb';
  static const gwCfg = '00002a25-0000-1000-8000-00805f9b34fb';

  // Vendor characteristics (6f8a9c__)
  static const gwCfgVnd = '6f8a9c10-2c1a-4b6f-8a11-8ddc1f4e7b25';
  static const engUnlock = '6f8a9c11-2c1a-4b6f-8a11-8ddc1f4e7b25';
  static const engPinSet = '6f8a9c12-2c1a-4b6f-8a11-8ddc1f4e7b25';
  static const evt = '6f8a9c13-2c1a-4b6f-8a11-8ddc1f4e7b25';
  static const peerRole = '6f8a9c14-2c1a-4b6f-8a11-8ddc1f4e7b25';
  static const capability = '6f8a9c19-2c1a-4b6f-8a11-8ddc1f4e7b25';
}
