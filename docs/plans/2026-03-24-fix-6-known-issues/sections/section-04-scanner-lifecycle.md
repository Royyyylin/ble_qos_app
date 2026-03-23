# Section 4: Scanner Lifecycle — Restart Scan on Return

**Layer:** Presentation
**Files Owned:**
- `lib/features/scanner/scanner_screen.dart`

**Depends On:** None
**Tasks:** 3 (Task 8, Task 9, Task 10)

---

### Task 8: [Presentation] Add RouteAware Mixin for Scan Lifecycle

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`

**Step 1: Write the failing test (BDD format)**

Scanner lifecycle involves Navigator integration — hard to unit test in isolation. We verify via manual Step 4.

**Step 2: Run baseline**
Run: `flutter test`
Expected: PASS (baseline)

**Step 3: Implementation edits**

Add `RouteAware` mixin to `_ScannerScreenState` to detect when the page becomes visible again after popping back from DeviceScreen.

EDIT_BLOCK 1
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'scan_device_tile.dart';
>>>
NEW_CONTENT: <<<

/// Global RouteObserver for scanner scan lifecycle management.
/// Register this in GoRouter/MaterialApp's navigatorObservers.
final scannerRouteObserver = RouteObserver<ModalRoute<void>>();
>>>
NOTE: RouteObserver instance needed for RouteAware mixin.

EDIT_BLOCK 2
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
class _ScannerScreenState extends ConsumerState<ScannerScreen> {
>>>
NEW_CONTENT: <<<
class _ScannerScreenState extends ConsumerState<ScannerScreen> with RouteAware {
>>>
NOTE: Add RouteAware mixin for didPopNext callback.

EDIT_BLOCK 3
FILE: lib/features/scanner/scanner_screen.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
  @override
  void initState() {
    super.initState();
    // Auto-start scan on screen load
    Future.microtask(() => _startScan());
  }
>>>
NEW_CONTENT: <<<

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      scannerRouteObserver.subscribe(this, route);
    }
  }

  /// Called when a pushed route is popped and this page becomes visible again.
  /// Issue #3: restart scan when returning from DeviceScreen.
  @override
  void didPopNext() {
    _startScan();
  }
>>>
NOTE: Issue #3 — Restart scan when user pops back from DeviceScreen. didPopNext is called by RouteObserver when the route above this one is popped.

EDIT_BLOCK 4
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  @override
  void dispose() {
    _stopScan(updateState: false);
    super.dispose();
  }
>>>
NEW_CONTENT: <<<
  @override
  void dispose() {
    scannerRouteObserver.unsubscribe(this);
    _stopScan(updateState: false);
    super.dispose();
  }
>>>
NOTE: Unsubscribe from RouteObserver on dispose to prevent leaks.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/features/scanner/scanner_screen.dart && git commit -m "ui(scanner): restart scan on return from DeviceScreen via RouteAware"

---

### Task 9: [Presentation] Register RouteObserver in App Navigation

**Layer:** Presentation
**DDD Pattern:** Adapter
**Files:**
- Modify: `lib/main.dart` (or wherever GoRouter is configured)

**Step 1: Identify GoRouter configuration**

Need to find where GoRouter or MaterialApp is configured and add `scannerRouteObserver` to `navigatorObservers`.

**Step 2: Run baseline**
Run: `flutter test`
Expected: PASS

**Step 3: Implementation edits**

NOTE: The exact EDIT_BLOCK depends on the GoRouter configuration location. The implementer should:
1. Read `lib/main.dart` to find the GoRouter configuration
2. Import `scanner_screen.dart` for `scannerRouteObserver`
3. Add `navigatorObservers: [scannerRouteObserver]` to the GoRouter or MaterialApp.router configuration

If GoRouter is used with `MaterialApp.router`, the observer goes in `MaterialApp.router(navigatorObservers: [scannerRouteObserver])`.

If `GoRouter` is used directly, ensure `observers: [scannerRouteObserver]` is added to the GoRouter constructor.

**Step 4: Run to verify it passes**
Run: `flutter test`
Expected: PASS

**Step 5: Commit**
git add lib/main.dart && git commit -m "ui(app): register scannerRouteObserver for scan lifecycle"

---

### Task 10: [Presentation] Verify RSSI Update Frequency (Issue #2)

**Layer:** Presentation
**DDD Pattern:** N/A (Investigation)
**Files:**
- No code changes expected

**Step 1: Investigation**

Issue #2 notes that RSSI updates may feel slow due to EMA smoothing (alpha=0.3). The current implementation in `ble_scanner.dart` already uses `continuousUpdates: true` and streams results immediately.

**Step 2: Verify scan parameters**

Check `ble_scanner.dart` lines 146-154 for:
- `continuousUpdates: true` ✓ (already set)
- No artificial delay between scan results ✓

**Step 3: No implementation edits needed**

The RSSI update frequency is inherent to BLE scan intervals (typically 100-500ms on Android). EMA alpha=0.3 provides smoothing without excessive delay. If users report issues, consider:
- Increasing EMA alpha (e.g., 0.5 for faster response)
- This is a tuning parameter, not a bug

**Step 4: Document as verified**

No code change needed — current implementation is correct per BLE best practices.

**Step 5: No commit needed**
