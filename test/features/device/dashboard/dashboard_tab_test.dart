import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';
import 'package:ble_qos_app/features/device/dashboard/dashboard_tab.dart';

void main() {
  // Helper to create a QosStatus from known values
  QosStatus makeStatus({
    int rssi = -55,
    int zone = 1,
    int phy = 2,
    int txPower = -8,
    int pdr = 95,
    int interval = 160,
  }) {
    return QosStatus(
      zone: zone,
      profile: 0,
      phy: phy,
      txPower: txPower,
      rssi: rssi,
      pdr: pdr,
      interval: interval,
      latency: 50,
      jitter: 5,
      tp: 10,
    );
  }

  Widget buildTestWidget({
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(body: DashboardTab(deviceId: 'test-device')),
      ),
    );
  }

  /// Default metrics override (empty stream) to avoid BLE dependency.
  Override metricsEmpty() =>
      metricsStreamProvider.overrideWith((ref) => const Stream.empty());

  testWidgets(
    'given statusStreamProvider emits QosStatus when DashboardTab renders then shows live metric values',
    (tester) async {
      final status = makeStatus(rssi: -55, zone: 1, phy: 2, txPower: -8, pdr: 95, interval: 160);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
          metricsEmpty(),
        ],
      ));
      await tester.pumpAndSettle();

      // New metric layout: RSSI, PDR, Latency, Jitter, PHY, TX Power
      expect(find.text('-55'), findsOneWidget);  // RSSI
      expect(find.text('95'), findsOneWidget);   // PDR
      expect(find.text('50'), findsOneWidget);   // Latency
      expect(find.text('5'), findsOneWidget);    // Jitter
      expect(find.text('2'), findsOneWidget);    // PHY
      expect(find.text('-8'), findsOneWidget);   // TX Power
    },
  );

  testWidgets(
    'given statusStreamProvider is loading when DashboardTab renders then shows placeholder dashes',
    (tester) async {
      // Never-completing stream = loading state
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => const Stream.empty()),
          metricsEmpty(),
        ],
      ));
      await tester.pump();

      // Should show '--' placeholders while loading
      expect(find.text('--'), findsWidgets);
    },
  );

  testWidgets(
    'given statusStreamProvider has error when DashboardTab renders then shows error message',
    (tester) async {
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith(
            (ref) => Stream.error('BLE disconnected'),
          ),
          metricsEmpty(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    },
  );

  testWidgets(
    'given QosStatus data when MetricCard renders then has semantics label with metric name and value',
    (tester) async {
      final status = makeStatus(rssi: -60, pdr: 88);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
          metricsEmpty(),
        ],
      ));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'RSSI.*-60.*dBm')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'PDR.*88.*%')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'given all-zero QosStatus when DashboardTab renders then shows dashes instead of 0',
    (tester) async {
      // All zeros = firmware has no data (ED not in session)
      const zeroStatus = QosStatus();
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(zeroStatus)),
          metricsEmpty(),
        ],
      ));
      await tester.pumpAndSettle();

      // All metric values should be '--' not '0'
      expect(find.text('0'), findsNothing);
      expect(find.text('--'), findsWidgets);
    },
  );

  testWidgets(
    'given metricsStreamProvider emits data when DashboardTab renders then shows throughput',
    (tester) async {
      final status = makeStatus();
      const metrics = QosMetricsV2(tpBps: 1024);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
          metricsStreamProvider.overrideWith((ref) => Stream.value(metrics)),
        ],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Throughput card may be below fold — scroll down
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('1024'), findsOneWidget); // Throughput
    },
  );
}
