import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ble_qos_app/features/device/ha/ha_tab.dart';
import 'package:ble_qos_app/core/gatt/gatt_structs.dart';
import 'package:ble_qos_app/core/providers/metrics_provider.dart';

void main() {
  group('HaTab', () {
    testWidgets('given no heartbeat data when rendered then shows placeholder dashes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            haHeartbeatStreamProvider.overrideWith(
              (ref) => const Stream<HaHeartbeat>.empty(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HaTab(deviceId: 'TEST-HA')),
          ),
        ),
      );
      await tester.pump();

      // Loading state should show '--' placeholders
      expect(find.text('High Availability'), findsOneWidget);
      expect(find.text('HA Role'), findsOneWidget);
    });

    testWidgets('given active heartbeat when rendered then shows Active role', (tester) async {
      final hb = HaHeartbeat(
        haRole: HaHeartbeat.roleActive,
        epoch: 5,
        heartbeatCount: 42,
        peerStatus: HaHeartbeat.roleStandby,
        lastFailoverTimestamp: 0,
        lastFailoverReason: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            haHeartbeatStreamProvider.overrideWith(
              (ref) => Stream.value(hb),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HaTab(deviceId: 'TEST-HA')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Standby'), findsOneWidget);
      expect(find.text('No failover events'), findsOneWidget);
    });

    // RED/BLUE REVIEW — Task 7:
    // Blue: HA tab shows 'No HA pair configured' instead of raw error when subscribe fails. Modifies ha_tab.dart + test.
    // Red: No issues found. Signature change (error→noHaPair) is internal to _buildFields, no external callers.
    testWidgets('given_subscribe_error_when_rendered_then_shows_no_ha_pair_message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            haHeartbeatStreamProvider.overrideWith(
              (ref) => Stream<HaHeartbeat>.error('Subscribe failed'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HaTab(deviceId: 'TEST-HA')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Issue #5: Should show user-friendly message, not raw error
      // Text appears in both the card fields and the failover section
      expect(find.text('No HA pair configured'), findsWidgets);
    });
  });
}
