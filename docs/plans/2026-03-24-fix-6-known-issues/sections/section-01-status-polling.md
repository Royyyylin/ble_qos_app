# Section 1: STATUS Polling Infrastructure

**Layer:** Infrastructure
**Files Owned:**
- `lib/core/providers/metrics_provider.dart`

**Depends On:** None
**Tasks:** 2 (Task 1, Task 2)

---

### Task 1: [Infrastructure] Add STATUS Polling Stream Provider

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/providers/metrics_provider.dart`

**Step 1: Write the failing test (BDD format)**

No separate test file — this is a provider-level change. The existing `dashboard_tab_test.dart` tests validate via provider overrides. We verify via Step 4.

**Step 2: Run to verify current tests pass**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: PASS (baseline)

**Step 3: Implementation edits**

Replace `statusStreamProvider` to use 2-second GATT read polling instead of relying solely on 4-byte notify. Keep 4-byte indexed notify for edStatusMap updates but poll full 13-byte STATUS for dashboard metrics.

EDIT_BLOCK 1
FILE: lib/core/providers/metrics_provider.dart
ACTION: REPLACE
ANCHOR: <<<
/// Live STATUS notify stream — auto-detects 13-byte full or 4-byte indexed format.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Keep last full status so 4-byte indexed notifies don't erase rssi/pdr/lat/jit.
  QosStatus lastFull = const QosStatus();

  // Initial read (full 13-byte struct)
  try {
    final data = await gatt.read(GattUuids.status);
    debugPrint('[METRICS] STATUS read ${data.length} bytes: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    if (data.length >= QosStatus.indexedSize) {
      lastFull = QosStatus.parse(data);
      debugPrint('[METRICS] STATUS parsed: rssi=${lastFull.rssi} pdr=${lastFull.pdr} lat=${lastFull.latency} jit=${lastFull.jitter} zone=${lastFull.zone} phy=${lastFull.phy} tx=${lastFull.txPower}');
      yield lastFull;
    }
  } catch (e) {
    debugPrint('[METRICS] STATUS initial read failed: $e');
  }

  // Subscribe to notify (may be 4-byte indexed or 13-byte full)
  try {
    debugPrint('[METRICS] STATUS subscribing...');
    final stream = await gatt.subscribe(GattUuids.status);
    debugPrint('[METRICS] STATUS subscribed OK');
    DateTime lastYield = DateTime.now();
    yield* stream
        .where((data) => data.length >= QosStatus.indexedSize)
        .map((data) {
          if (data.length >= QosStatus.size) {
            // Full 13-byte notify — update everything
            lastFull = QosStatus.parse(data);
            return lastFull;
          } else {
            // 4-byte indexed notify — merge with last full (keep rssi/pdr/lat/jit)
            final indexed = QosStatus.fromIndexedBytes(data);
            ref.read(edStatusMapProvider.notifier).update(indexed);
            // Merge: use indexed zone/profile/phy/tx, keep full rssi/pdr/lat/jit
            lastFull = QosStatus(
              rssi: lastFull.rssi,
              pdr: lastFull.pdr,
              latency: lastFull.latency,
              jitter: lastFull.jitter,
              zone: indexed.zone,
              profile: indexed.profile,
              phy: indexed.phy,
              txPower: indexed.txPower,
              interval: indexed.interval,
              edIndex: indexed.edIndex,
            );
            return lastFull;
          }
        })
        .where((_) {
          final now = DateTime.now();
          if (now.difference(lastYield).inMilliseconds < 1000) return false;
          lastYield = now;
          return true;
        });
  } catch (e) {
    debugPrint('[METRICS] STATUS subscribe failed: $e');
  }
});
>>>
NEW_CONTENT: <<<
/// STATUS polling interval — firmware sends only 4-byte indexed notify
/// (zone/profile/phy/tx). Full 13-byte STATUS (rssi/pdr/lat/jit) requires GATT read.
const _statusPollInterval = Duration(seconds: 2);

/// Live STATUS stream — polls full 13-byte STATUS every 2s via GATT read.
/// Also subscribes to 4-byte indexed notifies for edStatusMap updates.
final statusStreamProvider = StreamProvider.autoDispose<QosStatus>((ref) async* {
  final device = ref.watch(connectedDeviceProvider);
  if (device == null) return;

  final connector = ref.watch(bleConnectorProvider);
  final gatt = BleGatt(connector);

  // Subscribe to 4-byte indexed notifies for edStatusMap (fire-and-forget)
  try {
    final stream = await gatt.subscribe(GattUuids.status);
    stream
        .where((data) => data.length >= QosStatus.indexedSize && data.length < QosStatus.size)
        .listen((data) {
      final indexed = QosStatus.fromIndexedBytes(data);
      ref.read(edStatusMapProvider.notifier).update(indexed);
    });
  } catch (e) {
    debugPrint('[METRICS] STATUS subscribe for edStatusMap failed: $e');
  }

  // Poll full 13-byte STATUS every 2s
  while (true) {
    try {
      final data = await gatt.read(GattUuids.status);
      if (data.length >= QosStatus.indexedSize) {
        final status = QosStatus.parse(data);
        debugPrint('[METRICS] STATUS poll: rssi=${status.rssi} pdr=${status.pdr} lat=${status.latency} jit=${status.jitter}');
        yield status;
      }
    } catch (e) {
      debugPrint('[METRICS] STATUS poll read failed: $e');
      return; // Stop polling if read fails (disconnected)
    }
    await Future.delayed(_statusPollInterval);
    if (connector.state != BleConnectionState.connected) return;
  }
});
>>>
NOTE: Issue #1 — Dashboard STATUS not updating. Firmware only sends 4-byte indexed notify (zone/profile/phy/tx). Full 13-byte STATUS with rssi/pdr/lat/jit only available via GATT read. Pattern matches deviceInfoProvider which also polls.

**Step 4: Run to verify it passes**
Run: `flutter test test/features/device/dashboard/dashboard_tab_test.dart`
Expected: PASS

**Step 5: Commit**
git add lib/core/providers/metrics_provider.dart && git commit -m "infra(metrics): switch STATUS from notify-only to 2s polling for full 13-byte read"

---

### Task 2: [Infrastructure] Keep edStatusMap Notify Subscription Active

**Layer:** Infrastructure
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/core/providers/metrics_provider.dart` (already modified in Task 1)

**Step 1: Verify edStatusMap still works**

The 4-byte indexed notify subscription in Task 1 feeds edStatusMap. Verify the existing Roster tests still pass.

**Step 2: Run to verify**
Run: `flutter test test/providers/ed_roster_provider_test.dart`
Expected: PASS

**Step 3: Implementation edits**

No additional edits needed — Task 1 already includes the `stream.listen` for edStatusMap updates. This task is a verification checkpoint.

**Step 4: Run full test suite**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
No commit needed — Task 1 commit covers this.
