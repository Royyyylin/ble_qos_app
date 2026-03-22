import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';

void main() {
  group('QosMetricsV2', () {
    test('fromBytes parses 20-byte struct correctly', () {
      // Build a 20-byte payload matching firmware layout:
      // pdr_x100=9850(LE), lat=12(LE), jit=3(LE), rssi=-55(int8),
      // prof=1, phy=2, tx=-4(int8), tp=1024(LE), tp_peak=2048(LE),
      // enomem=5(LE), eagain=2(LE), stack_free=512(LE)
      final data = Uint8List(20);
      final bd = ByteData.sublistView(data);
      bd.setUint16(0, 9850, Endian.little);   // pdr_x100 → 99%
      bd.setUint16(2, 12, Endian.little);      // lat_ms
      bd.setUint16(4, 3, Endian.little);       // jit_ms
      bd.setInt8(6, -55);                       // rssi_dbm
      bd.setUint8(7, 1);                        // prof (BALANCED)
      bd.setUint8(8, 2);                        // phy (2M)
      bd.setInt8(9, -4);                        // tx_power
      bd.setUint16(10, 1024, Endian.little);   // tp_Bps
      bd.setUint16(12, 2048, Endian.little);   // tp_peak_Bps
      bd.setUint16(14, 5, Endian.little);      // enomem_cnt
      bd.setUint16(16, 2, Endian.little);      // eagain_cnt
      bd.setUint16(18, 512, Endian.little);    // min_stack_free

      final m = QosMetricsV2.fromBytes(data);

      expect(m.pdr, 99);        // 9850/100 rounded
      expect(m.latency, 12);
      expect(m.jitter, 3);
      expect(m.rssi, -55);
      expect(m.profile, 1);
      expect(m.phy, 2);
      expect(m.txPower, -4);
      expect(m.tpBps, 1024);
      expect(m.tpPeakBps, 2048);
      expect(m.enomemCnt, 5);
      expect(m.eagainCnt, 2);
      expect(m.minStackFree, 512);
    });

    test('fromBytes throws on short data', () {
      expect(
        () => QosMetricsV2.fromBytes(Uint8List(19)),
        throwsArgumentError,
      );
    });

    test('fromBytes accepts data longer than 20 bytes', () {
      final data = Uint8List(24); // extra bytes at end
      final bd = ByteData.sublistView(data);
      bd.setUint16(0, 5000, Endian.little); // pdr 50%
      bd.setInt8(6, -70);

      final m = QosMetricsV2.fromBytes(data);
      expect(m.pdr, 50);
      expect(m.rssi, -70);
    });
  });
}
