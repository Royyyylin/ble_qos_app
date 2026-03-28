import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_adapter.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_value_state.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_snapshot.dart';

void main() {
  group('TelemetryAdapter.fromQosStatus', () {
    test('P1 complete payload — all fields present', () {
      final status = QosStatus(
        rssi: -52, pdr: 99, latency: 12, jitter: 8,
        phy: 2, txPower: 4, tp: 100,
      );
      final snap = TelemetryAdapter.fromQosStatus('ed:AA', status);

      expect(snap.rssi.state, TelemetryValueState.present);
      expect(snap.rssi.value, -52);
      expect(snap.pdr.value, 99.0);
      expect(snap.latency.value, 12);
      expect(snap.jitter.value, 8);
      expect(snap.profile, PayloadProfile.p1);
    });

    test('all-zero status — treated as unknown, not error', () {
      const status = QosStatus();
      final snap = TelemetryAdapter.fromQosStatus('ed:BB', status);

      expect(snap.rssi.state, TelemetryValueState.unknown);
      expect(snap.rssi.hasValue, isFalse);
      expect(snap.profile, PayloadProfile.p1);
    });
  });

  group('TelemetryAdapter.fromIndexedStatus', () {
    test('indexed 4-byte — RSSI/PDR/latency marked sparse', () {
      const indexed = QosStatus(phy: 2, txPower: 0);
      final snap = TelemetryAdapter.fromIndexedStatus('ed:CC', indexed);

      expect(snap.rssi.state, TelemetryValueState.sparse);
      expect(snap.pdr.state, TelemetryValueState.sparse);
      expect(snap.latency.state, TelemetryValueState.sparse);
      expect(snap.jitter.state, TelemetryValueState.sparse);
      expect(snap.phy.state, TelemetryValueState.present);
      expect(snap.phy.value, 2);
      expect(snap.profile, PayloadProfile.p0);
    });
  });

  group('TelemetryAdapter.notConnected', () {
    test('all fields unknown for offline ED', () {
      final snap = TelemetryAdapter.notConnected('ed:DD');
      expect(snap.rssi.state, TelemetryValueState.unknown);
      expect(snap.pdr.state, TelemetryValueState.unknown);
      expect(snap.profile, isNull);
    });
  });

  group('TelemetryAdapter.notSynced', () {
    test('all fields notSynced', () {
      final snap = TelemetryAdapter.notSynced('ed:EE');
      expect(snap.rssi.state, TelemetryValueState.notSynced);
      expect(snap.throughput.state, TelemetryValueState.notSynced);
    });
  });

  group('TelemetryAdapter.merge', () {
    test('incoming P0 sparse keeps existing P1 values as stale', () {
      final existing = TelemetrySnapshot(
        edId: 'ed:FF',
        rssi: const MetricValue.present(-52),
        pdr: const MetricValue.present(99.5),
        latency: const MetricValue.present(12),
        jitter: const MetricValue.present(8),
        phy: const MetricValue.present(2),
        txPower: const MetricValue.present(4),
        throughput: const MetricValue.present(100),
        profile: PayloadProfile.p1,
        lastUpdated: DateTime.now(),
      );

      final incoming = TelemetrySnapshot(
        edId: 'ed:FF',
        rssi: const MetricValue.sparse(),
        pdr: const MetricValue.sparse(),
        latency: const MetricValue.sparse(),
        jitter: const MetricValue.sparse(),
        phy: const MetricValue.present(1),  // P0 still has PHY
        txPower: const MetricValue.present(-4),
        throughput: const MetricValue.sparse(),
        profile: PayloadProfile.p0,
        lastUpdated: DateTime.now(),
      );

      final merged = TelemetryAdapter.merge(existing, incoming);

      // P0 sparse fields → keep old values as stale
      expect(merged.rssi.state, TelemetryValueState.stale);
      expect(merged.rssi.value, -52);
      expect(merged.pdr.state, TelemetryValueState.stale);

      // P0 present fields → use new values
      expect(merged.phy.state, TelemetryValueState.present);
      expect(merged.phy.value, 1);
      expect(merged.txPower.value, -4);

      // Profile switched
      expect(merged.profile, PayloadProfile.p0);
    });

    test('incoming P1 complete replaces all fields', () {
      final existing = TelemetrySnapshot(
        edId: 'ed:GG',
        rssi: const MetricValue.stale(-52),
        profile: PayloadProfile.p0,
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 5)),
      );

      final incoming = TelemetrySnapshot(
        edId: 'ed:GG',
        rssi: const MetricValue.present(-60),
        pdr: const MetricValue.present(98.0),
        latency: const MetricValue.present(15),
        jitter: const MetricValue.present(10),
        phy: const MetricValue.present(2),
        txPower: const MetricValue.present(4),
        throughput: const MetricValue.present(200),
        profile: PayloadProfile.p1,
        lastUpdated: DateTime.now(),
      );

      final merged = TelemetryAdapter.merge(existing, incoming);

      expect(merged.rssi.state, TelemetryValueState.present);
      expect(merged.rssi.value, -60);
      expect(merged.profile, PayloadProfile.p1);
    });
  });
}
