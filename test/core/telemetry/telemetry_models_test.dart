import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_value_state.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_snapshot.dart';
import 'package:ble_qos_app/core/telemetry/device_state.dart';

void main() {
  group('MetricValue', () {
    test('present has value and is displayable', () {
      const m = MetricValue.present(-52);
      expect(m.value, -52);
      expect(m.state, TelemetryValueState.present);
      expect(m.hasValue, isTrue);
      expect(m.isDisplayable, isTrue);
    });

    test('sparse has no value and is not displayable', () {
      const m = MetricValue<int>.sparse();
      expect(m.value, isNull);
      expect(m.state, TelemetryValueState.sparse);
      expect(m.hasValue, isFalse);
      expect(m.isDisplayable, isFalse);
    });

    test('stale has value and is displayable', () {
      const m = MetricValue.stale(-65);
      expect(m.value, -65);
      expect(m.state, TelemetryValueState.stale);
      expect(m.hasValue, isTrue);
      expect(m.isDisplayable, isTrue);
    });

    test('unknown has no value', () {
      const m = MetricValue<int>.unknown();
      expect(m.value, isNull);
      expect(m.state, TelemetryValueState.unknown);
      expect(m.hasValue, isFalse);
      expect(m.isDisplayable, isFalse);
    });

    test('notSynced has no value', () {
      const m = MetricValue<int>.notSynced();
      expect(m.value, isNull);
      expect(m.state, TelemetryValueState.notSynced);
      expect(m.hasValue, isFalse);
    });
  });

  group('TelemetrySnapshot', () {
    test('default snapshot has all unknown fields', () {
      const snap = TelemetrySnapshot(edId: 'ed:AA:BB');
      expect(snap.rssi.state, TelemetryValueState.unknown);
      expect(snap.pdr.state, TelemetryValueState.unknown);
      expect(snap.latency.state, TelemetryValueState.unknown);
      expect(snap.profile, isNull);
    });

    test('P1 snapshot has all present fields', () {
      final snap = TelemetrySnapshot(
        edId: 'ed:AA:BB',
        rssi: const MetricValue.present(-52),
        pdr: const MetricValue.present(99.5),
        latency: const MetricValue.present(12),
        jitter: const MetricValue.present(8),
        phy: const MetricValue.present(2),
        txPower: const MetricValue.present(4),
        throughput: const MetricValue.present(0),
        profile: PayloadProfile.p1,
      );
      expect(snap.rssi.state, TelemetryValueState.present);
      expect(snap.rssi.value, -52);
      expect(snap.profile, PayloadProfile.p1);
    });

    test('P0 snapshot has sparse fields — not error', () {
      const snap = TelemetrySnapshot(
        edId: 'ed:AA:BB',
        rssi: MetricValue.sparse(),
        pdr: MetricValue.sparse(),
        latency: MetricValue.sparse(),
        jitter: MetricValue.sparse(),
        phy: MetricValue.present(2),
        txPower: MetricValue.present(0),
        throughput: MetricValue.sparse(),
        profile: PayloadProfile.p0,
      );
      expect(snap.rssi.state, TelemetryValueState.sparse);
      expect(snap.rssi.hasValue, isFalse);
      expect(snap.phy.hasValue, isTrue);
      expect(snap.profile, PayloadProfile.p0);
    });

    test('copyWith preserves unchanged fields', () {
      const snap = TelemetrySnapshot(
        edId: 'ed:AA:BB',
        rssi: MetricValue.present(-52),
        profile: PayloadProfile.p1,
      );
      final updated = snap.copyWith(rssi: const MetricValue.present(-60));
      expect(updated.rssi.value, -60);
      expect(updated.pdr.state, TelemetryValueState.unknown); // unchanged
      expect(updated.profile, PayloadProfile.p1);
    });
  });

  group('EdDeviceState', () {
    test('sparse profile does not imply degraded or down', () {
      const ed = EdDeviceState(
        edId: 'ed:11:22:33:44:55:66',
        edMac: '11:22:33:44:55:66',
        assignmentState: AssignmentState.active,
        isSparseProfile: true,
        lastPayloadProfile: PayloadProfile.p0,
      );
      expect(ed.assignmentState, AssignmentState.active);
      expect(ed.isSparseProfile, isTrue);
      // Active + sparse profile is a valid state — not degraded
    });

    test('missing telemetry with active assignment is valid', () {
      const ed = EdDeviceState(
        edId: 'ed:11:22',
        edMac: '11:22',
        assignmentState: AssignmentState.active,
      );
      expect(ed.hasTelemetry, isFalse);
      // No telemetry yet but active assignment — waiting for first data
    });

    test('displayName follows alias > firmware > edId precedence', () {
      const ed1 = EdDeviceState(edId: 'ed:AA', edMac: 'AA', alias: 'MyED');
      expect(ed1.displayName, 'MyED');

      const ed2 = EdDeviceState(edId: 'ed:AA', edMac: 'AA', firmwareName: 'FED-01');
      expect(ed2.displayName, 'FED-01');

      const ed3 = EdDeviceState(edId: 'ed:AA', edMac: 'AA');
      expect(ed3.displayName, 'ed:AA');
    });
  });

  group('GwSummaryState', () {
    test('nullable fields are accepted', () {
      const gw = GwSummaryState(gwId: 'gw:CC:DD', gwMac: 'CC:DD');
      expect(gw.fwVersion, isNull);
      expect(gw.uptimeSeconds, isNull);
      expect(gw.resetCount, isNull);
      expect(gw.displayName, 'gw:CC:DD');
    });
  });

  group('SyncState', () {
    test('default is zero revision, not syncing', () {
      const s = SyncState();
      expect(s.lastSyncedRevision, 0);
      expect(s.isSyncing, isFalse);
      expect(s.pendingOpsCount, 0);
    });
  });

  group('CentralAuthState', () {
    test('default is not authenticated', () {
      const a = CentralAuthState();
      expect(a.isAuthenticated, isFalse);
      expect(a.centralRole, isNull);
    });
  });
}
