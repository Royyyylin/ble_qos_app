import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/ble/ble_models.dart';
import 'package:ble_qos_app/features/scanner/scan_device_tile.dart';

void main() {
  ScannedDevice makeDevice({
    String name = 'GW-Test-01',
    int rssi = -55,
    String id = 'AA:BB:CC:DD:EE:FF',
  }) {
    return ScannedDevice(
      id: id,
      name: name,
      rssi: rssi,
      smoothedRssi: rssi.toDouble(),
      status: DeviceStatus.online,
      lastSeen: DateTime.now(),
    );
  }

  testWidgets(
    'given ScannedDevice when ScanDeviceTile renders then has semantics label with device info',
    (tester) async {
      final device = makeDevice(name: 'GW-Test-01', rssi: -55);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScanDeviceTile(device: device, onTap: () {}),
        ),
      ));

      final semantics = tester.getSemantics(find.byType(ScanDeviceTile));
      expect(semantics.label, contains('GW-Test-01'));
      expect(semantics.label, contains('Gateway'));
      expect(semantics.label, contains('-55'));
    },
  );

  testWidgets(
    'given ScanDeviceTile when rendered then has double tap hint for accessibility',
    (tester) async {
      final device = makeDevice();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScanDeviceTile(device: device, onTap: () {}),
        ),
      ));

      final semantics = tester.getSemantics(find.byType(ScanDeviceTile));
      expect(semantics.hint, contains('connect'));
    },
  );
}
