# Section 3: Dashboard Throughput & HA Tab Presentation Fixes

**Layer:** Presentation
**Files Owned:**
- `lib/features/device/dashboard/dashboard_tab.dart`
- `lib/features/device/ha/ha_tab.dart`
- `test/features/device/dashboard/dashboard_tab_test.dart`
- `test/features/device/ha/ha_tab_test.dart`

**Depends On:** Section 1 (STATUS polling must be in place)
**Tasks:** 3 (Task 5, Task 6, Task 7)

---

### Task 5: [Presentation] Add Throughput N/A Test

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `test/features/device/dashboard/dashboard_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

EDIT_BLOCK 1
FILE: test/features/device/dashboard/dashboard_tab_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
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
>>>
NEW_CONTENT: <<<

  testWidgets(
    'given_tpBps_is_zero_when_dashboard_renders_then_shows_na_not_dashes',
    (tester) async {
      final status = makeStatus();
      const metrics = QosMetricsV2(tpBps: 0);
      await tester.pumpWidget(buildTestWidget(
        overrides: [
          statusStreamProvider.overrideWith((ref) => Stream.value(status)),
          metricsStreamProvider.overrideWith((ref) => Stream.value(metrics)),
        ],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Scroll down to throughput card
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Issue #6: tpBps=0 should show 'N/A' not '--'
      expect(find.text('N/A'), findsOneWidget);
    },
  );
>>>
NOTE: Test for Issue #6 — Throughput displays N/A when tp_Bps=0 in non-TP mode.

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart --name "given_tpBps_is_zero"`
Expected: FAIL (currently shows '--')

**Step 3: No edits in this task — test only**

**Step 4: Skip — test expected to fail**

**Step 5: Commit**
git add test/features/device/dashboard/dashboard_tab_test.dart && git commit -m "test(dashboard): add throughput N/A display test for tpBps=0"

---

### Task 6: [Presentation] Fix Throughput to Show N/A When tpBps=0

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/device/dashboard/dashboard_tab.dart`

**Step 1: Write the failing test (BDD format)**

Already written in Task 5.

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart --name "given_tpBps_is_zero"`
Expected: FAIL

**Step 3: Implementation edits**

EDIT_BLOCK 1
FILE: lib/features/device/dashboard/dashboard_tab.dart
ACTION: REPLACE
ANCHOR: <<<
    (
      label: 'Throughput',
      unit: 'B/s',
      valueOf: (s, m) => m == null || _isNoData(s) ? '--' : (m.tpBps == 0 ? '--' : '${m.tpBps}'),
      health: null,
      tooltip: TooltipContent.throughput,
    ),
>>>
NEW_CONTENT: <<<
    (
      label: 'Throughput',
      unit: 'B/s',
      valueOf: (s, m) => m == null || _isNoData(s) ? '--' : (m.tpBps == 0 ? 'N/A' : '${m.tpBps}'),
      health: null,
      tooltip: TooltipContent.throughput,
    ),
>>>
NOTE: Issue #6 — tpBps=0 means non-TP mode (firmware doesn't fill throughput). Show 'N/A' instead of '--' to distinguish from "no data at all".

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/dashboard/dashboard_tab.dart && git commit -m "ui(dashboard): show N/A for throughput when tpBps=0 in non-TP mode"

---

### Task 7: [Presentation] HA Tab Shows 'No HA Pair' Instead of Waiting Forever

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/device/ha/ha_tab.dart`
- Modify: `test/features/device/ha/ha_tab_test.dart`

**Step 1: Write the failing test (BDD format)**

EDIT_BLOCK 1
FILE: test/features/device/ha/ha_tab_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
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
>>>
NEW_CONTENT: <<<

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
      expect(find.text('No HA pair configured'), findsOneWidget);
    });
>>>
NOTE: Test for Issue #5 — HA shows friendly message when no HA pair exists.

**Step 2: Run to verify it fails**
Run: `flutter test test/features/device/ha/ha_tab_test.dart --name "given_subscribe_error"`
Expected: FAIL (currently shows 'Error: Subscribe failed')

**Step 3: Implementation edits**

EDIT_BLOCK 2
FILE: lib/features/device/ha/ha_tab.dart
ACTION: REPLACE
ANCHOR: <<<
            child: hbAsync.when(
                loading: () => _buildFields(context, null),
                error: (e, _) => _buildFields(context, null, error: '$e'),
                data: (hb) => _buildFields(context, hb),
              ),
>>>
NEW_CONTENT: <<<
            child: hbAsync.when(
                loading: () => _buildFields(context, null),
                error: (_, __) => _buildFields(context, null, noHaPair: true),
                data: (hb) => _buildFields(context, hb),
              ),
>>>
NOTE: Error state treated as "no HA pair" — single GW without HA pairing won't produce heartbeat.

EDIT_BLOCK 3
FILE: lib/features/device/ha/ha_tab.dart
ACTION: REPLACE
ANCHOR: <<<
          Expanded(
            child: hbAsync.when(
              loading: () => const Center(
                child: Text('Waiting for heartbeat...', style: TextStyle(color: AppColors.textSecondary)),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (hb) => _buildFailoverInfo(context, hb),
            ),
          ),
>>>
NEW_CONTENT: <<<
          Expanded(
            child: hbAsync.when(
              loading: () => const Center(
                child: Text('Waiting for heartbeat...', style: TextStyle(color: AppColors.textSecondary)),
              ),
              error: (_, __) => const Center(
                child: Text('No HA pair configured', style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (hb) => _buildFailoverInfo(context, hb),
            ),
          ),
>>>
NOTE: Issue #5 — Replace raw error text with user-friendly message.

EDIT_BLOCK 4
FILE: lib/features/device/ha/ha_tab.dart
ACTION: REPLACE
ANCHOR: <<<
  Widget _buildFields(BuildContext context, HaHeartbeat? hb, {String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
>>>
NEW_CONTENT: <<<
  Widget _buildFields(BuildContext context, HaHeartbeat? hb, {bool noHaPair = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (noHaPair)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No HA pair configured', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
>>>
NOTE: Change error string parameter to bool noHaPair for clarity.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/ha/ha_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/features/device/ha/ha_tab.dart test/features/device/ha/ha_tab_test.dart && git commit -m "ui(ha): show 'No HA pair configured' instead of waiting forever"
