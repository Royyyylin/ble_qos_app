# Section 2: Capability Negotiation Domain Layer

**Layer:** Domain
**Files Owned:**
- `lib/core/capability/degradation_info.dart` (create)
- `lib/core/capability/capability_negotiator.dart` (modify)
- `test/core/capability/degradation_info_test.dart` (create)
- `test/core/capability/capability_negotiator_test.dart` (modify)

**Depends On:** None
**Tasks:** 2 (Task 4, Task 5)

---

### Task 4: [Domain] DegradationInfo Value Object

**Layer:** Domain
**DDD Pattern:** ValueObject
**Files:**
- Create: `lib/core/capability/degradation_info.dart`
- Create: `test/core/capability/degradation_info_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/capability/degradation_info_test.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/degradation_info.dart';

void main() {
  group('DegradationInfo', () {
    test('given_version_mismatch_when_created_then_stores_all_fields', () {
      final info = DegradationInfo(
        capId: 'qos_monitor',
        deviceVersion: 0,
        requiredVersion: 1,
        tabLabel: 'Dashboard',
      );
      expect(info.capId, 'qos_monitor');
      expect(info.deviceVersion, 0);
      expect(info.requiredVersion, 1);
      expect(info.tabLabel, 'Dashboard');
    });

    test('given_degradation_info_when_message_accessed_then_returns_human_readable', () {
      final info = DegradationInfo(
        capId: 'ha_runtime',
        deviceVersion: 0,
        requiredVersion: 1,
        tabLabel: 'HA',
      );
      expect(info.message, contains('v0'));
      expect(info.message, contains('v1'));
    });

    test('given_two_identical_infos_when_compared_then_equal', () {
      final a = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      final b = DegradationInfo(
        capId: 'qos_monitor', deviceVersion: 0,
        requiredVersion: 1, tabLabel: 'Dashboard',
      );
      expect(a, equals(b));
    });
  });
}
>>>
NOTE: BDD tests for DegradationInfo value object.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/capability/degradation_info_test.dart`
Expected: FAIL

**Step 3: Implementation edits**

```
EDIT_BLOCK 2
FILE: lib/core/capability/degradation_info.dart
ACTION: CREATE_FILE
NEW_CONTENT: <<<
/// Metadata about an incompatible capability for Graceful Degradation UI.
/// Shown as a warning badge + tooltip on the affected tab.
class DegradationInfo {
  final String capId;
  final int deviceVersion;
  final int requiredVersion;
  final String tabLabel;

  const DegradationInfo({
    required this.capId,
    required this.deviceVersion,
    required this.requiredVersion,
    required this.tabLabel,
  });

  /// Human-readable degradation message for tooltip display.
  String get message =>
      '$capId: device has v$deviceVersion, requires v$requiredVersion';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DegradationInfo &&
          capId == other.capId &&
          deviceVersion == other.deviceVersion &&
          requiredVersion == other.requiredVersion &&
          tabLabel == other.tabLabel;

  @override
  int get hashCode =>
      Object.hash(capId, deviceVersion, requiredVersion, tabLabel);

  @override
  String toString() => 'DegradationInfo($message)';
}
>>>
NOTE: Value object for Graceful Degradation UI — carries version mismatch details.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/capability/degradation_info_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/capability/degradation_info.dart test/core/capability/degradation_info_test.dart && git commit -m "domain(capability): add DegradationInfo value object for graceful degradation UI"`

---

### Task 5: [Domain] Enhance NegotiationResult with DegradationInfo List

**Layer:** Domain
**DDD Pattern:** ValueObject (enhanced)
**Files:**
- Modify: `lib/core/capability/capability_negotiator.dart`
- Modify: `test/core/capability/capability_negotiator_test.dart`

**Step 1: Write the failing test (BDD format)**

```
EDIT_BLOCK 1
FILE: test/core/capability/capability_negotiator_test.dart
ACTION: INSERT_AFTER
ANCHOR: <<<
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
>>>
NEW_CONTENT: <<<
import 'package:ble_qos_app/core/capability/degradation_info.dart';
>>>
NOTE: Add import for DegradationInfo.
```

```
EDIT_BLOCK 2
FILE: test/core/capability/capability_negotiator_test.dart
ACTION: INSERT_BEFORE
ANCHOR: <<<
    test('negotiate ignores unknown capabilities', () {
>>>
NEW_CONTENT: <<<
    test('given_incompatible_cap_when_negotiated_then_produces_degradation_info', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 0), // too old
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.degraded, hasLength(1));
      expect(result.degraded.first.capId, 'qos_monitor');
      expect(result.degraded.first.deviceVersion, 0);
      expect(result.degraded.first.requiredVersion, 1);
      expect(result.degraded.first.tabLabel, 'Dashboard');
    });

    test('given_all_compatible_when_negotiated_then_degraded_is_empty', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.degraded, isEmpty);
    });

>>>
NOTE: Tests for DegradationInfo production during negotiation.
```

**Step 2: Run to verify it fails**
Run: `flutter test test/core/capability/capability_negotiator_test.dart`
Expected: FAIL (NegotiationResult has no `degraded` field)

**Step 3: Implementation edits**

```
EDIT_BLOCK 3
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';
>>>
NEW_CONTENT: <<<
// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';
import 'degradation_info.dart';
>>>
NOTE: Add DegradationInfo import.
```

```
EDIT_BLOCK 4
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
  });
}
>>>
NEW_CONTENT: <<<
/// Result of capability negotiation — spec §5.3.
class NegotiationResult {
  final List<String> enabledTabs;
  final List<Capability> incompatible;
  final List<String> unknown;

  /// Degradation details for incompatible capabilities — used by UI badges.
  final List<DegradationInfo> degraded;

  const NegotiationResult({
    required this.enabledTabs,
    required this.incompatible,
    required this.unknown,
    this.degraded = const [],
  });

  /// True when all known capabilities are incompatible (show "limited mode" banner).
  bool get isLimitedMode =>
      enabledTabs.isEmpty && incompatible.isNotEmpty;
}
>>>
NOTE: Add degraded list and isLimitedMode helper.
```

```
EDIT_BLOCK 5
FILE: lib/core/capability/capability_negotiator.dart
ACTION: REPLACE
ANCHOR: <<<
  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
    );
  }
>>>
NEW_CONTENT: <<<
  static NegotiationResult negotiate(List<Capability> deviceCaps) {
    final enabledTabs = <String>[];
    final incompatible = <Capability>[];
    final unknown = <String>[];
    final degraded = <DegradationInfo>[];

    for (final cap in deviceCaps) {
      final handler = CapabilityRegistry.getHandler(cap.id);
      if (handler == null) {
        unknown.add(cap.id);
      } else if (cap.version < handler.minVersion) {
        incompatible.add(cap);
        degraded.add(DegradationInfo(
          capId: cap.id,
          deviceVersion: cap.version,
          requiredVersion: handler.minVersion,
          tabLabel: handler.tabLabel,
        ));
      } else {
        enabledTabs.add(handler.tabLabel);
      }
    }

    return NegotiationResult(
      enabledTabs: enabledTabs,
      incompatible: incompatible,
      unknown: unknown,
      degraded: degraded,
    );
  }
>>>
NOTE: Produce DegradationInfo for each incompatible capability.
```

**Step 4: Run to verify it passes**
Run: `flutter test test/core/capability/capability_negotiator_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/core/capability/capability_negotiator.dart lib/core/capability/degradation_info.dart test/core/capability/capability_negotiator_test.dart && git commit -m "domain(capability): enhance NegotiationResult with DegradationInfo for graceful degradation"`
