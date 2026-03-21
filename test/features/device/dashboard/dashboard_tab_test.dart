import 'dart:typed_data';

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

  testWidgets(
    'given statusStreamProvider emits QosStatus when DashboardTab renders then shows live metric values',
    (tester) async {
      final status = makeStatus(rssi: -55, zone: 1, phy: 2, txPower: -8, pdr: 95, interval: 160);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('-55'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('-8'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('160'), findsOneWidget);
    },
  );

  testWidgets(
    'given statusStreamProvider is loading when DashboardTab renders then shows placeholder dashes',
    (tester) async {
      // Never-completing stream = loading state
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => const Stream.empty()),
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
}
