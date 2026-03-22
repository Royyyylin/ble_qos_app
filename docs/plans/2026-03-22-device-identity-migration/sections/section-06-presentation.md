# Section 6: Presentation Layer — Scanner, DeviceScreen, Navigation

**Layer:** Presentation
**Files Owned:**
- `lib/features/scanner/scanner_screen.dart` (modify)
- `lib/features/device/device_screen.dart` (modify)
- `lib/main.dart` (no code change — semantics only)
- `pubspec.yaml` (modify — comment only, uuid not needed since we self-generate)

**Depends On:** Section 3 (ScannedDevice.mac), Section 4 (ConnectedDevice.mac), Section 5 (capabilityNegotiationProvider)
**Tasks:** 4 (Task 14, Task 15, Task 16, Task 17)

---

### Task 14: [Presentation] ScannerScreen — Use StableId for Navigation + MAC for Connect

**Layer:** Presentation
**DDD Pattern:** UI Handler
**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`

**Step 1: No new failing test (UI integration)**

The scanner screen changes are transparent to existing widget tests since
`device.id` is now StableId and `device.mac` carries the platform identifier.

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/features/scanner/scanner_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    try {
      // ConnectionOrchestrator: connect → handshake → navigate
      await connector.connect(device.id);
      // ConnectionEstablished — navigate to DeviceScreen
      if (mounted) context.push('/device/${device.id}');
>>>
NEW_CONTENT: <<<
    try {
      // ConnectionOrchestrator: connect → handshake → navigate
      // device.id is StableId — BleConnector resolves to MAC internally
      await connector.connect(device.id);
      // ConnectionEstablished — navigate with StableId in route
      if (mounted) context.push('/device/${device.id}');
>>>
NOTE: Clarify that device.id is now StableId. BleConnector resolves MAC internally.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/features/scanner/scan_device_tile_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/features/scanner/scanner_screen.dart && git commit -m "ui(scanner): clarify StableId usage in navigation and connection"`

---

### Task 15: [Presentation] DeviceScreen — AppBar Title from Device Name

**Layer:** Presentation
**DDD Pattern:** UI Handler
**Files:**
- Modify: `lib/features/device/device_screen.dart`

**Step 1: No new failing test (cosmetic UI fix)**

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
  /// Build the common AppBar with ConnectionStateIndicator.
  AppBar _buildAppBar(BleConnectionState bleState, {PreferredSizeWidget? bottom}) {
    return AppBar(
      title: Text(deviceId),
      actions: [ConnectionStateIndicator(state: bleState)],
      bottom: bottom,
    );
  }
>>>
NEW_CONTENT: <<<
  /// Build the common AppBar with ConnectionStateIndicator.
  /// Shows device name instead of StableId (UUIDv4 is not user-friendly).
  AppBar _buildAppBar(BleConnectionState bleState, WidgetRef ref, {PreferredSizeWidget? bottom}) {
    final connDevice = ref.watch(connectedDeviceProvider);
    final title = connDevice?.name ?? deviceId;
    return AppBar(
      title: Text(title),
      actions: [ConnectionStateIndicator(state: bleState)],
      bottom: bottom,
    );
  }
>>>
NOTE: Show device name in AppBar instead of StableId UUID.
```

```
EDIT_BLOCK 2
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    // Show loading while connecting/handshaking
    if (bleState == BleConnectionState.connecting || bleState == BleConnectionState.handshaking) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen if connection lost or errored
    if (bleState == BleConnectionState.error || bleState == BleConnectionState.disconnected) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
        body: ConnectionErrorScreen(
>>>
NEW_CONTENT: <<<
    // Show loading while connecting/handshaking
    if (bleState == BleConnectionState.connecting || bleState == BleConnectionState.handshaking) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen if connection lost or errored
    if (bleState == BleConnectionState.error || bleState == BleConnectionState.disconnected) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: ConnectionErrorScreen(
>>>
NOTE: Pass ref to _buildAppBar for device name lookup.
```

```
EDIT_BLOCK 3
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    if (tabs.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
>>>
NEW_CONTENT: <<<
    if (tabs.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
>>>
NOTE: Pass ref to _buildAppBar in empty tabs branch.
```

```
EDIT_BLOCK 4
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    if (tabs.length == 1) {
      return Scaffold(
        appBar: _buildAppBar(bleState),
>>>
NEW_CONTENT: <<<
    if (tabs.length == 1) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
>>>
NOTE: Pass ref to _buildAppBar in single tab branch.
```

```
EDIT_BLOCK 5
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: _buildAppBar(
          bleState,
          bottom: TabBar(
>>>
NEW_CONTENT: <<<
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: _buildAppBar(
          bleState,
          ref,
          bottom: TabBar(
>>>
NOTE: Pass ref to _buildAppBar in multi-tab branch.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/features/device/device_screen_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/features/device/device_screen.dart && git commit -m "ui(device): show device name in AppBar instead of StableId UUID"`

---

### Task 16: [Presentation] DeviceScreen — GATT Capability Negotiation + Degradation UI

**Layer:** Presentation
**DDD Pattern:** UI Handler
**Files:**
- Modify: `lib/features/device/device_screen.dart`

**Step 1: No new test (widget integration)**

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';
>>>
NEW_CONTENT: <<<
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/capability/capability_reader.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';
import 'package:ble_qos_app/core/capability/degradation_info.dart';
>>>
NOTE: Import CapabilityReader and DegradationInfo for GATT-based negotiation.
```

```
EDIT_BLOCK 2
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    // Get capabilities from connected device role (fallback when no Capability Characteristic)
    final connDevice = ref.watch(connectedDeviceProvider);
    final capabilities = CapabilityRegistry.fallbackForRole(connDevice?.role ?? 0);
    final result = CapabilityNegotiator.negotiate(capabilities);
    final tabs = <_TabEntry>[];

    // Add capability-driven tabs
    for (final tabLabel in result.enabledTabs) {
      final widget = _widgetForTab(tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(label: tabLabel, widget: widget));
      }
    }
>>>
NEW_CONTENT: <<<
    // Get capabilities via GATT read → role fallback negotiation order
    final connDevice = ref.watch(connectedDeviceProvider);
    final capResult = ref.watch(capabilityNegotiationProvider);
    final result = capResult.valueOrNull ??
        CapabilityNegotiator.negotiate(
          CapabilityRegistry.fallbackForRole(connDevice?.role ?? 0),
        );
    final tabs = <_TabEntry>[];

    // Build degradation lookup for warning badges
    final degradationMap = <String, DegradationInfo>{};
    for (final d in result.degraded) {
      degradationMap[d.tabLabel] = d;
    }

    // Add capability-driven tabs (including degraded ones with warning badges)
    for (final tabLabel in result.enabledTabs) {
      final widget = _widgetForTab(tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(label: tabLabel, widget: widget));
      }
    }
    // Add degraded tabs with warning badge
    for (final d in result.degraded) {
      final widget = _widgetForTab(d.tabLabel);
      if (widget != null) {
        tabs.add(_TabEntry(
          label: '⚠ ${d.tabLabel}',
          widget: widget,
          degradation: d,
        ));
      }
    }
>>>
NOTE: Use capabilityNegotiationProvider for GATT read order. Add degraded tabs with warning badge.
```

```
EDIT_BLOCK 3
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
class _TabEntry {
  final String label;
  final Widget widget;

  const _TabEntry({required this.label, required this.widget});
}
>>>
NEW_CONTENT: <<<
class _TabEntry {
  final String label;
  final Widget widget;
  final DegradationInfo? degradation;

  const _TabEntry({
    required this.label,
    required this.widget,
    this.degradation,
  });
}
>>>
NOTE: Add degradation field to _TabEntry for tooltip display.
```

```
EDIT_BLOCK 4
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
            tabs: tabs.map((t) => Tab(text: t.label)).toList(),
>>>
NEW_CONTENT: <<<
            tabs: tabs.map((t) => Tab(
              child: t.degradation != null
                  ? Tooltip(
                      message: t.degradation!.message,
                      child: Text(t.label),
                    )
                  : Text(t.label),
            )).toList(),
>>>
NOTE: Show tooltip on degraded tabs with version mismatch details.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/features/device/device_screen_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/features/device/device_screen.dart && git commit -m "ui(device): add GATT capability negotiation with graceful degradation badges"`

---

### Task 17: [Presentation] DeviceScreen — Limited Mode Banner

**Layer:** Presentation
**DDD Pattern:** UI Handler
**Files:**
- Modify: `lib/features/device/device_screen.dart`

**Step 1: No new test (visual UI element)**

**Step 2: Skip**

**Step 3: Implementation edits**

```
EDIT_BLOCK 1
FILE: lib/features/device/device_screen.dart
ACTION: REPLACE
ANCHOR: <<<
    if (tabs.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: const Center(
          child: Text(
            'No compatible capabilities',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
>>>
NEW_CONTENT: <<<
    if (tabs.isEmpty) {
      // Limited Mode: all caps incompatible or no caps at all
      return Scaffold(
        appBar: _buildAppBar(bleState, ref),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                result.isLimitedMode
                    ? 'Limited Mode — device capabilities incompatible'
                    : 'No compatible capabilities',
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (result.degraded.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...result.degraded.map((d) => Text(
                  d.message,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )),
              ],
            ],
          ),
        ),
      );
    }
>>>
NOTE: Show "Limited Mode" banner when all capabilities are incompatible.
```

**Step 4: Run to verify it compiles**
Run: `flutter test test/features/device/device_screen_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/features/device/device_screen.dart && git commit -m "ui(device): add limited mode banner for fully incompatible devices"`
