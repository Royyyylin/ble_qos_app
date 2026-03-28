import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_qos_app/core/telemetry/device_state.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_snapshot.dart';
import 'package:ble_qos_app/core/telemetry/telemetry_value_state.dart';
import 'package:ble_qos_app/core/providers/telemetry_state_provider.dart';
import 'package:ble_qos_app/core/providers/roster_state_provider.dart';

void main() {
  group('RosterItemState', () {
    test('P1 present metrics display correctly', () {
      const device = EdDeviceState(
        edId: 'ed:AA:BB',
        edMac: 'AA:BB',
        assignmentState: AssignmentState.active,
        telemetry: TelemetrySnapshot(
          edId: 'ed:AA:BB',
          rssi: MetricValue.present(-52),
          pdr: MetricValue.present(99.5),
          latency: MetricValue.present(12),
          jitter: MetricValue.present(8),
          phy: MetricValue.present(2),
          txPower: MetricValue.present(4),
          throughput: MetricValue.present(100),
          profile: PayloadProfile.p1,
        ),
      );
      final item = RosterItemState(device);

      expect(item.rssiDisplay, '-52');
      expect(item.pdrDisplay, '99.5');
      expect(item.latencyDisplay, '12');
      expect(item.jitterDisplay, '8');
      expect(item.isOnline, isTrue);
      expect(item.isSparse, isFalse);
    });

    test('P0 sparse metrics show -- not error', () {
      const device = EdDeviceState(
        edId: 'ed:CC:DD',
        edMac: 'CC:DD',
        assignmentState: AssignmentState.active,
        isSparseProfile: true,
        lastPayloadProfile: PayloadProfile.p0,
        telemetry: TelemetrySnapshot(
          edId: 'ed:CC:DD',
          rssi: MetricValue.sparse(),
          pdr: MetricValue.sparse(),
          latency: MetricValue.sparse(),
          jitter: MetricValue.sparse(),
          phy: MetricValue.present(2),
          txPower: MetricValue.present(0),
          throughput: MetricValue.sparse(),
          profile: PayloadProfile.p0,
        ),
      );
      final item = RosterItemState(device);

      expect(item.rssiDisplay, '--');
      expect(item.pdrDisplay, '--');
      expect(item.phyDisplay, '2');
      expect(item.isSparse, isTrue);
      // Still active — sparse ≠ degraded/down
      expect(item.isOnline, isTrue);
      expect(item.assignmentState, AssignmentState.active);
    });

    test('stale metrics still display value', () {
      const device = EdDeviceState(
        edId: 'ed:EE:FF',
        edMac: 'EE:FF',
        telemetry: TelemetrySnapshot(
          edId: 'ed:EE:FF',
          rssi: MetricValue.stale(-65),
          pdr: MetricValue.stale(98.0),
        ),
      );
      final item = RosterItemState(device);

      expect(item.rssiDisplay, '-65');
      expect(item.pdrDisplay, '98.0');
    });

    test('unknown metrics show --', () {
      const device = EdDeviceState(
        edId: 'ed:11:22',
        edMac: '11:22',
        telemetry: TelemetrySnapshot(edId: 'ed:11:22'),
      );
      final item = RosterItemState(device);

      expect(item.rssiDisplay, '--');
      expect(item.pdrDisplay, '--');
    });

    test('notSynced metrics show --', () {
      const device = EdDeviceState(
        edId: 'ed:33:44',
        edMac: '33:44',
        telemetry: TelemetrySnapshot(
          edId: 'ed:33:44',
          rssi: MetricValue.notSynced(),
          pdr: MetricValue.notSynced(),
        ),
      );
      final item = RosterItemState(device);

      expect(item.rssiDisplay, '--');
    });

    test('throughput 0 shows N/A', () {
      const device = EdDeviceState(
        edId: 'ed:55:66',
        edMac: '55:66',
        telemetry: TelemetrySnapshot(
          edId: 'ed:55:66',
          throughput: MetricValue(0, TelemetryValueState.present),
        ),
      );
      final item = RosterItemState(device);

      expect(item.throughputDisplay, 'N/A');
    });

    test('displayName follows alias > firmware > edId', () {
      const d1 = EdDeviceState(edId: 'ed:AA', edMac: 'AA', alias: 'MyED');
      expect(RosterItemState(d1).displayName, 'MyED');

      const d2 = EdDeviceState(edId: 'ed:AA', edMac: 'AA', firmwareName: 'FED-01');
      expect(RosterItemState(d2).displayName, 'FED-01');

      const d3 = EdDeviceState(edId: 'ed:AA', edMac: 'AA');
      expect(RosterItemState(d3).displayName, 'ed:AA');
    });
  });

  group('rosterItemsProvider', () {
    test('sorts online first then by edId', () {
      final container = ProviderContainer(overrides: [
        edDeviceStateMapProvider.overrideWith((ref) => <String, EdDeviceState>{
            'ed:CC': const EdDeviceState(
              edId: 'ed:CC', edMac: 'CC',
              assignmentState: AssignmentState.pending,
            ),
            'ed:AA': const EdDeviceState(
              edId: 'ed:AA', edMac: 'AA',
              assignmentState: AssignmentState.active,
            ),
            'ed:BB': const EdDeviceState(
              edId: 'ed:BB', edMac: 'BB',
              assignmentState: AssignmentState.active,
            ),
          }),
      ]);
      addTearDown(container.dispose);

      final items = container.read(rosterItemsProvider);
      expect(items.length, 3);
      expect(items[0].edId, 'ed:AA'); // online, A
      expect(items[1].edId, 'ed:BB'); // online, B
      expect(items[2].edId, 'ed:CC'); // pending (not online)
    });
  });

  group('edDetailProvider', () {
    test('returns device by edId', () {
      final container = ProviderContainer(overrides: [
        edDeviceStateMapProvider.overrideWith((ref) => <String, EdDeviceState>{
            'ed:AA': const EdDeviceState(edId: 'ed:AA', edMac: 'AA', alias: 'Test'),
          }),
      ]);
      addTearDown(container.dispose);

      final detail = container.read(edDetailProvider('ed:AA'));
      expect(detail?.alias, 'Test');

      final missing = container.read(edDetailProvider('ed:ZZ'));
      expect(missing, isNull);
    });
  });
}
