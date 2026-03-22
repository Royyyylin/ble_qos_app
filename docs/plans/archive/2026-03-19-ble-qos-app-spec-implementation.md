# BLE QoS App — Spec Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full BLE QoS Mobile App design spec — theme, auth, capability system, scanner overhaul, device screens, provisioning, data layer, and CBOR codec.

**Architecture:** Incremental migration from v1 skeleton to spec-compliant v2. Domain models first (pure Dart, testable), then infrastructure (Drift DB, CBOR), then application layer (providers), finally presentation (GoRouter + screens). Each task is independently committable.

**Tech Stack:** Flutter, flutter_blue_plus, Riverpod, GoRouter, Drift (SQLite), cbor, shared_preferences

**Test Command:** `flutter test`

**Reference Spec:** `~/ble_qos_demo/ble_qos_demo_V1.2m/docs/superpowers/specs/2026-03-19-ble-qos-mobile-app-design.md`
**Research Brief:** `docs/research/2026-03-19-implement-ble-qos-mobile-app-per-design--research.md`

---

## File Structure

### New Files
- `lib/core/theme/app_colors.dart` — color constants (spec §8.1)
- `lib/core/theme/app_theme.dart` — ThemeData dark tech theme (spec §8)
- `lib/core/auth/auth_session.dart` — three-tier session with dual timeout + lockout
- `lib/core/auth/pin_validator.dart` — PIN hashing + validation + failure counting
- `lib/core/auth/permission_guard.dart` — permission matrix check (spec §3.2)
- `lib/core/capability/capability_model.dart` — Capability data class
- `lib/core/capability/capability_registry.dart` — cap_id → handler mapping
- `lib/core/capability/capability_negotiator.dart` — connection-time negotiation
- `lib/core/data/database.dart` — Drift database definition
- `lib/core/data/tables/devices.dart` — devices table
- `lib/core/data/tables/alerts.dart` — alerts table
- `lib/core/data/tables/audit_log.dart` — audit_log table
- `lib/core/data/tables/device_telemetry.dart` — telemetry table
- `lib/core/data/repositories/device_repository.dart` — device CRUD
- `lib/core/data/repositories/alert_repository.dart` — alert CRUD + aggregation
- `lib/core/data/repositories/audit_repository.dart` — audit log CRUD
- `lib/core/ble/cbor_codec.dart` — CBOR encode/decode for capability char
- `lib/core/ble/manufacturer_data.dart` — advertising manufacturer data parser
- `lib/core/providers/scan_provider.dart` — enhanced scan state
- `lib/core/providers/connection_provider.dart` — connection + capability state
- `lib/core/providers/auth_provider.dart` — auth session provider
- `lib/features/scanner/scanner_screen.dart` — Fleet Overview Dashboard
- `lib/features/scanner/fleet_summary.dart` — online/warn/offline stat cards
- `lib/features/scanner/scan_device_tile.dart` — device card in list
- `lib/features/device/device_screen.dart` — capability-driven tab layout
- `lib/features/device/dashboard/dashboard_tab.dart` — telemetry dashboard
- `lib/features/device/control/control_tab.dart` — QoS control
- `lib/features/device/ha/ha_tab.dart` — HA status display
- `lib/features/device/admin/admin_tab.dart` — engineer admin
- `lib/features/provisioning/provisioning_screen.dart` — ROLE + network_id
- `lib/features/audit/audit_screen.dart` — audit log view
- `test/core/theme/app_colors_test.dart`
- `test/core/auth/auth_session_test.dart`
- `test/core/auth/pin_validator_test.dart`
- `test/core/auth/permission_guard_test.dart`
- `test/core/capability/capability_model_test.dart`
- `test/core/capability/capability_registry_test.dart`
- `test/core/capability/capability_negotiator_test.dart`
- `test/core/ble/manufacturer_data_test.dart`
- `test/core/data/repositories/device_repository_test.dart`
- `test/core/data/repositories/alert_repository_test.dart`
- `test/core/data/repositories/audit_repository_test.dart`

### Modified Files
- `pubspec.yaml` — add deps: cbor, drift, sqlite3_flutter_libs, shared_preferences, intl
- `lib/core/gatt/gatt_uuids.dart` — add Capability UUID `6f8a9c19`
- `lib/main.dart` — GoRouter + dark theme + ProviderScope
- `.github/workflows/ci.yml` — add build_runner step if needed

### Files NOT to Modify
- `lib/core/gatt/gatt_structs.dart` — firmware-coupled, only extend
- `lib/core/gatt/gatt_peer_role.dart` — firmware-defined enum
- `lib/core/ble/ble_reconnect.dart` — stable, no changes needed

---

### Task 1: Dark Tech Theme — Color Constants and ThemeData

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `test/core/theme/app_colors_test.dart`

- [ ] **Step 1: Write failing test for color constants**

```dart
// test/core/theme/app_colors_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/theme/app_colors.dart';

void main() {
  test('AppColors.background is Deep Navy #0A0E1A', () {
    expect(AppColors.background.value, 0xFF0A0E1A);
  });
  test('AppColors.primary is Electric Cyan #00E5FF', () {
    expect(AppColors.primary.value, 0xFF00E5FF);
  });
  test('AppColors.surface is Dark Slate #141B2D', () {
    expect(AppColors.surface.value, 0xFF141B2D);
  });
  test('AppColors.error is Signal Red #FF1744', () {
    expect(AppColors.error.value, 0xFFFF1744);
  });
  test('AppColors.success is Neon Green #00E676', () {
    expect(AppColors.success.value, 0xFF00E676);
  });
  test('AppColors.warning is Amber Orange #FF6B35', () {
    expect(AppColors.warning.value, 0xFFFF6B35);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: FAIL — file not found

- [ ] **Step 3: Implement app_colors.dart**

```dart
// lib/core/theme/app_colors.dart
import 'dart:ui';

/// Color palette — spec §8.1 Dark Tech theme.
class AppColors {
  AppColors._();

  static const background   = Color(0xFF0A0E1A); // Deep Navy
  static const surface      = Color(0xFF141B2D); // Dark Slate
  static const surfaceVar   = Color(0xFF1E2740); // Steel Blue
  static const primary      = Color(0xFF00E5FF); // Electric Cyan
  static const secondary    = Color(0xFF7C4DFF); // Neon Purple
  static const warning      = Color(0xFFFF6B35); // Amber Orange
  static const error        = Color(0xFFFF1744); // Signal Red
  static const success      = Color(0xFF00E676); // Neon Green
  static const stale        = Color(0xFF546E7A); // Muted Grey
  static const textPrimary  = Color(0xFFE0E0E0); // Light Grey
  static const textSecondary = Color(0xFF90A4AE); // Blue Grey
}
```

- [ ] **Step 4: Implement app_theme.dart**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Dark tech theme — spec §8.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.background,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textPrimary,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: AppColors.textSecondary, fontSize: 11),
    ),
  );
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/ test/core/theme/
git commit -m "feat: add dark tech theme — color palette and ThemeData (spec §8)"
```

---

### Task 2: Three-Tier Auth — PIN Validator

**Files:**
- Create: `lib/core/auth/pin_validator.dart`
- Create: `test/core/auth/pin_validator_test.dart`

- [ ] **Step 1: Write failing tests for PIN validator**

```dart
// test/core/auth/pin_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/pin_validator.dart';

void main() {
  group('PinValidator', () {
    late PinValidator validator;

    setUp(() => validator = PinValidator());

    test('validate returns true for correct PIN', () {
      validator.setPin('123456');
      expect(validator.validate('123456'), isTrue);
    });

    test('validate returns false for wrong PIN', () {
      validator.setPin('123456');
      expect(validator.validate('000000'), isFalse);
    });

    test('lockout after 5 failed attempts', () {
      validator.setPin('123456');
      for (var i = 0; i < 5; i++) {
        validator.validate('wrong$i');
      }
      expect(validator.isLockedOut, isTrue);
      expect(validator.validate('123456'), isFalse); // locked out
    });

    test('lockout expires after duration', () async {
      validator = PinValidator(lockoutDuration: Duration(milliseconds: 50));
      validator.setPin('123456');
      for (var i = 0; i < 5; i++) {
        validator.validate('wrong$i');
      }
      expect(validator.isLockedOut, isTrue);
      await Future.delayed(Duration(milliseconds: 60));
      expect(validator.isLockedOut, isFalse);
    });

    test('successful validate resets failure count', () {
      validator.setPin('123456');
      validator.validate('wrong1');
      validator.validate('wrong2');
      validator.validate('123456'); // success resets
      validator.validate('wrong3');
      validator.validate('wrong4');
      validator.validate('wrong5');
      validator.validate('wrong6');
      // 4 failures after reset, not locked out
      expect(validator.isLockedOut, isFalse);
    });

    test('remainingAttempts decreases on failure', () {
      validator.setPin('123456');
      expect(validator.remainingAttempts, 5);
      validator.validate('wrong');
      expect(validator.remainingAttempts, 4);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/auth/pin_validator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement pin_validator.dart**

```dart
// lib/core/auth/pin_validator.dart
import 'dart:convert';
import 'package:crypto/crypto.dart' show sha256;

/// PIN validator with lockout — spec §3.1.
/// Stores hashed PIN, tracks failed attempts.
class PinValidator {
  PinValidator({
    this.maxAttempts = 5,
    this.lockoutDuration = const Duration(minutes: 10),
  });

  final int maxAttempts;
  final Duration lockoutDuration;

  String? _pinHash;
  int _failureCount = 0;
  DateTime? _lockedUntil;

  int get remainingAttempts => maxAttempts - _failureCount;

  bool get isLockedOut {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _failureCount = 0;
      return false;
    }
    return true;
  }

  void setPin(String pin) {
    _pinHash = _hash(pin);
    _failureCount = 0;
    _lockedUntil = null;
  }

  bool get hasPin => _pinHash != null;

  /// Returns true if PIN matches. Returns false if wrong or locked out.
  bool validate(String pin) {
    if (isLockedOut) return false;
    if (_pinHash == null) return false;

    if (_hash(pin) == _pinHash) {
      _failureCount = 0;
      return true;
    }

    _failureCount++;
    if (_failureCount >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
    }
    return false;
  }

  static String _hash(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
```

Note: `crypto` package is needed. Add to pubspec.yaml: `crypto: ^3.0.0`

- [ ] **Step 4: Add crypto dependency and run test**

Run: `flutter pub add crypto && flutter test test/core/auth/pin_validator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/pin_validator.dart test/core/auth/pin_validator_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add PIN validator with lockout (spec §3.1)"
```

---

### Task 3: Three-Tier Auth — Session Manager

**Files:**
- Create: `lib/core/auth/auth_session.dart`
- Create: `test/core/auth/auth_session_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/auth/auth_session_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/auth_session.dart';

void main() {
  group('AuthSession', () {
    test('starts at Role-0 (normal)', () {
      final session = AuthSession();
      expect(session.currentRole, AuthRole.normal);
    });

    test('elevate to maintenance sets role', () {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      expect(session.currentRole, AuthRole.maintenance);
    });

    test('elevate to engineer sets role', () {
      final session = AuthSession();
      session.elevate(AuthRole.engineer);
      expect(session.currentRole, AuthRole.engineer);
    });

    test('demote returns to normal', () {
      final session = AuthSession();
      session.elevate(AuthRole.maintenance);
      session.demote();
      expect(session.currentRole, AuthRole.normal);
    });

    test('isElevated returns true for maintenance and engineer', () {
      final session = AuthSession();
      expect(session.isElevated, isFalse);
      session.elevate(AuthRole.maintenance);
      expect(session.isElevated, isTrue);
    });

    test('idle timeout config differs by role', () {
      expect(AuthRole.maintenance.idleTimeout, const Duration(minutes: 15));
      expect(AuthRole.engineer.idleTimeout, const Duration(minutes: 5));
    });

    test('absolute timeout config differs by role', () {
      expect(AuthRole.maintenance.absoluteTimeout, const Duration(hours: 8));
      expect(AuthRole.engineer.absoluteTimeout, const Duration(hours: 4));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/auth/auth_session_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement auth_session.dart**

```dart
// lib/core/auth/auth_session.dart
import 'dart:async';

/// Three-tier auth roles — spec §3.1.
enum AuthRole {
  normal,       // Role-0: no auth
  maintenance,  // Role-1: 6-digit PIN (App-side)
  engineer;     // Role-2: 8-digit PIN (firmware ENG_UNLOCK)

  Duration get idleTimeout => switch (this) {
    normal => Duration.zero,
    maintenance => const Duration(minutes: 15),
    engineer => const Duration(minutes: 5),
  };

  Duration get absoluteTimeout => switch (this) {
    normal => Duration.zero,
    maintenance => const Duration(hours: 8),
    engineer => const Duration(hours: 4),
  };
}

/// Auth session state — manages role elevation, idle + absolute timeouts.
class AuthSession {
  AuthRole _role = AuthRole.normal;
  DateTime? _elevatedAt;
  DateTime? _lastActivity;
  Timer? _idleTimer;
  Timer? _absoluteTimer;
  void Function()? _onExpired;

  AuthRole get currentRole => _role;
  bool get isElevated => _role != AuthRole.normal;

  void elevate(AuthRole role, {void Function()? onExpired}) {
    _role = role;
    _elevatedAt = DateTime.now();
    _lastActivity = DateTime.now();
    _onExpired = onExpired;
    _startTimers();
  }

  void demote() {
    _role = AuthRole.normal;
    _elevatedAt = null;
    _lastActivity = null;
    _cancelTimers();
  }

  void touch() {
    if (!isElevated) return;
    _lastActivity = DateTime.now();
    _restartIdleTimer();
  }

  void _startTimers() {
    _cancelTimers();
    if (_role.idleTimeout > Duration.zero) {
      _idleTimer = Timer(_role.idleTimeout, _expire);
    }
    if (_role.absoluteTimeout > Duration.zero) {
      _absoluteTimer = Timer(_role.absoluteTimeout, _expire);
    }
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_role.idleTimeout > Duration.zero) {
      _idleTimer = Timer(_role.idleTimeout, _expire);
    }
  }

  void _expire() {
    demote();
    _onExpired?.call();
  }

  void _cancelTimers() {
    _idleTimer?.cancel();
    _absoluteTimer?.cancel();
    _idleTimer = null;
    _absoluteTimer = null;
  }

  void dispose() {
    _cancelTimers();
  }
}
```

- [ ] **Step 4: Run test to verify passes**

Run: `flutter test test/core/auth/auth_session_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/auth_session.dart test/core/auth/auth_session_test.dart
git commit -m "feat: add three-tier auth session with dual timeouts (spec §3.1)"
```

---

### Task 4: Three-Tier Auth — Permission Guard

**Files:**
- Create: `lib/core/auth/permission_guard.dart`
- Create: `test/core/auth/permission_guard_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/auth/permission_guard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/auth/permission_guard.dart';
import 'package:ble_qos_app/core/auth/auth_session.dart';

void main() {
  group('PermissionGuard', () {
    test('normal user can read all', () {
      expect(PermissionGuard.canRead(AuthRole.normal, GattAction.status), isTrue);
      expect(PermissionGuard.canRead(AuthRole.normal, GattAction.metrics), isTrue);
    });

    test('normal user cannot write CTRL', () {
      expect(PermissionGuard.canWrite(AuthRole.normal, GattAction.ctrl), isFalse);
    });

    test('maintenance can write CTRL and GW_CFG', () {
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.ctrl), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.gwCfg), isTrue);
    });

    test('maintenance cannot write MODE or ROLE', () {
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.mode), isFalse);
      expect(PermissionGuard.canWrite(AuthRole.maintenance, GattAction.role), isFalse);
    });

    test('engineer can write all writable', () {
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.ctrl), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.mode), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.role), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.engUnlock), isTrue);
      expect(PermissionGuard.canWrite(AuthRole.engineer, GattAction.engPinSet), isTrue);
    });

    test('maintenance CMD reboot requires confirmation', () {
      expect(PermissionGuard.requiresConfirmation(AuthRole.maintenance, GattAction.cmdReboot), isTrue);
      expect(PermissionGuard.requiresConfirmation(AuthRole.engineer, GattAction.cmdReboot), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify fails**

Run: `flutter test test/core/auth/permission_guard_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement permission_guard.dart**

```dart
// lib/core/auth/permission_guard.dart
import 'auth_session.dart';

/// GATT actions that require permission checks — spec §3.2.
enum GattAction {
  // Read-only (all roles)
  status, metrics, rssi, evt,
  // Handshake (all roles)
  peerRole,
  // Control (maintenance+)
  ctrl, gwCfg, ping, cmdReboot,
  // Admin (engineer only)
  mode, role, engUnlock, engPinSet,
}

/// Permission matrix — spec §3.2.
class PermissionGuard {
  PermissionGuard._();

  static bool canRead(AuthRole role, GattAction action) => true; // all roles can read

  static bool canWrite(AuthRole role, GattAction action) {
    return switch (action) {
      GattAction.peerRole => true,
      GattAction.ctrl || GattAction.gwCfg || GattAction.ping =>
        role == AuthRole.maintenance || role == AuthRole.engineer,
      GattAction.cmdReboot =>
        role == AuthRole.maintenance || role == AuthRole.engineer,
      GattAction.mode || GattAction.role || GattAction.engUnlock || GattAction.engPinSet =>
        role == AuthRole.engineer,
      _ => false,
    };
  }

  /// Maintenance CMD reboot needs confirmation dialog — spec §3.2 "W*".
  static bool requiresConfirmation(AuthRole role, GattAction action) {
    return role == AuthRole.maintenance && action == GattAction.cmdReboot;
  }
}
```

- [ ] **Step 4: Run test**

Run: `flutter test test/core/auth/permission_guard_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/auth/permission_guard.dart test/core/auth/permission_guard_test.dart
git commit -m "feat: add permission guard matrix (spec §3.2)"
```

---

### Task 5: Capability System — Model and Registry

**Files:**
- Create: `lib/core/capability/capability_model.dart`
- Create: `lib/core/capability/capability_registry.dart`
- Create: `test/core/capability/capability_model_test.dart`
- Create: `test/core/capability/capability_registry_test.dart`
- Modify: `lib/core/gatt/gatt_uuids.dart` — add Capability UUID

- [ ] **Step 1: Write failing tests for capability model and registry**

```dart
// test/core/capability/capability_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';

void main() {
  test('Capability equality by id and version', () {
    const a = Capability(id: 'qos_monitor', version: 1);
    const b = Capability(id: 'qos_monitor', version: 1);
    expect(a, equals(b));
  });

  test('Capability inequality on version', () {
    const a = Capability(id: 'qos_monitor', version: 1);
    const b = Capability(id: 'qos_monitor', version: 2);
    expect(a, isNot(equals(b)));
  });
}
```

```dart
// test/core/capability/capability_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';

void main() {
  group('CapabilityRegistry', () {
    test('has handler for qos_monitor', () {
      expect(CapabilityRegistry.hasHandler('qos_monitor'), isTrue);
    });

    test('has handler for ha_runtime', () {
      expect(CapabilityRegistry.hasHandler('ha_runtime'), isTrue);
    });

    test('returns null for unknown capability', () {
      expect(CapabilityRegistry.getHandler('pressure_sensor'), isNull);
    });

    test('isCompatible returns true for matching version', () {
      expect(
        CapabilityRegistry.isCompatible(const Capability(id: 'qos_monitor', version: 1)),
        isTrue,
      );
    });

    test('isCompatible returns false for too-old version', () {
      expect(
        CapabilityRegistry.isCompatible(const Capability(id: 'qos_monitor', version: 0)),
        isFalse,
      );
    });

    test('fallback capabilities for gateway role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x02); // ROLE_GATEWAY
      expect(caps.map((c) => c.id), containsAll(['qos_monitor', 'ed_roster', 'ha_runtime']));
    });

    test('fallback capabilities for end_device role', () {
      final caps = CapabilityRegistry.fallbackForRole(0x01); // ROLE_END_DEVICE
      expect(caps.map((c) => c.id), contains('qos_monitor'));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/capability/`
Expected: FAIL

- [ ] **Step 3: Add Capability UUID to gatt_uuids.dart**

Add to `lib/core/gatt/gatt_uuids.dart`:
```dart
static const capability = '6f8a9c19-2c1a-4b6f-8a11-8ddc1f4e7b25';
```

- [ ] **Step 4: Implement capability_model.dart**

```dart
// lib/core/capability/capability_model.dart

/// A device capability — spec §5.1.
class Capability {
  final String id;
  final int version;

  const Capability({required this.id, required this.version});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Capability && id == other.id && version == other.version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() => 'Capability($id v$version)';
}
```

- [ ] **Step 5: Implement capability_registry.dart**

```dart
// lib/core/capability/capability_registry.dart
import 'capability_model.dart';

/// Handler metadata for a capability — spec §5.2.
class CapabilityHandler {
  final String tabLabel;
  final int minVersion;

  const CapabilityHandler({required this.tabLabel, required this.minVersion});
}

/// Capability registry — maps cap_id → handler + min version.
class CapabilityRegistry {
  CapabilityRegistry._();

  static const _handlers = <String, CapabilityHandler>{
    'qos_monitor':  CapabilityHandler(tabLabel: 'Dashboard', minVersion: 1),
    'ha_runtime':   CapabilityHandler(tabLabel: 'HA', minVersion: 1),
    'ed_roster':    CapabilityHandler(tabLabel: 'Roster', minVersion: 1),
    'central_sync': CapabilityHandler(tabLabel: 'Sync', minVersion: 1),
    'demo_traffic': CapabilityHandler(tabLabel: 'Demo', minVersion: 1),
  };

  static bool hasHandler(String capId) => _handlers.containsKey(capId);

  static CapabilityHandler? getHandler(String capId) => _handlers[capId];

  static bool isCompatible(Capability cap) {
    final handler = _handlers[cap.id];
    if (handler == null) return false;
    return cap.version >= handler.minVersion;
  }

  /// Fallback when Capability Characteristic is absent — spec §5.3.
  static List<Capability> fallbackForRole(int roleValue) {
    return switch (roleValue) {
      0x02 => const [  // ROLE_GATEWAY
        Capability(id: 'qos_monitor', version: 1),
        Capability(id: 'ed_roster', version: 1),
        Capability(id: 'ha_runtime', version: 1),
      ],
      0x01 => const [  // ROLE_END_DEVICE
        Capability(id: 'qos_monitor', version: 1),
      ],
      0x04 => const [  // ROLE_CC
        Capability(id: 'central_sync', version: 1),
        Capability(id: 'ha_runtime', version: 1),
      ],
      _ => const [],
    };
  }
}
```

- [ ] **Step 6: Run tests**

Run: `flutter test test/core/capability/`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/core/capability/ test/core/capability/ lib/core/gatt/gatt_uuids.dart
git commit -m "feat: add capability model and registry with role fallback (spec §5)"
```

---

### Task 6: Capability Negotiator

**Files:**
- Create: `lib/core/capability/capability_negotiator.dart`
- Create: `test/core/capability/capability_negotiator_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/core/capability/capability_negotiator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_negotiator.dart';
import 'package:ble_qos_app/core/capability/capability_registry.dart';

void main() {
  group('CapabilityNegotiator', () {
    test('negotiate returns enabled tabs for compatible capabilities', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 1),
        const Capability(id: 'ha_runtime', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, containsAll(['Dashboard', 'HA']));
      expect(result.incompatible, isEmpty);
      expect(result.unknown, isEmpty);
    });

    test('negotiate marks incompatible version', () {
      final caps = [
        const Capability(id: 'qos_monitor', version: 0), // too old
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, isEmpty);
      expect(result.incompatible, hasLength(1));
    });

    test('negotiate ignores unknown capabilities', () {
      final caps = [
        const Capability(id: 'pressure_sensor', version: 1),
        const Capability(id: 'qos_monitor', version: 1),
      ];
      final result = CapabilityNegotiator.negotiate(caps);
      expect(result.enabledTabs, contains('Dashboard'));
      expect(result.unknown, contains('pressure_sensor'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify fails**

Run: `flutter test test/core/capability/capability_negotiator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement capability_negotiator.dart**

```dart
// lib/core/capability/capability_negotiator.dart
import 'capability_model.dart';
import 'capability_registry.dart';

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

/// Negotiate device capabilities against local registry — spec §5.3.
class CapabilityNegotiator {
  CapabilityNegotiator._();

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
}
```

- [ ] **Step 4: Run test**

Run: `flutter test test/core/capability/capability_negotiator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/capability/capability_negotiator.dart test/core/capability/capability_negotiator_test.dart
git commit -m "feat: add capability negotiator for connection-time tab assembly (spec §5.3)"
```

---

### Task 7: Manufacturer Data Parser

**Files:**
- Create: `lib/core/ble/manufacturer_data.dart`
- Create: `test/core/ble/manufacturer_data_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/core/ble/manufacturer_data_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/manufacturer_data.dart';

void main() {
  group('ManufacturerData', () {
    test('parse valid GW payload', () {
      // protocol=1, role=2(GW), network_id=0x0001, ed_count=3, ha_role=1(active)
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.protocolVersion, 1);
      expect(data.role, 2);
      expect(data.networkId, 1);
      expect(data.edCount, 3);
      expect(data.haRole, 1);
    });

    test('parse valid ED payload (shorter)', () {
      // protocol=1, role=1(ED), network_id=0x0002
      final bytes = Uint8List.fromList([1, 1, 2, 0]);
      final data = ManufacturerData.parse(bytes);
      expect(data, isNotNull);
      expect(data!.role, 1);
      expect(data.networkId, 2);
      expect(data.edCount, isNull);
    });

    test('parse returns null for too-short payload', () {
      final bytes = Uint8List.fromList([1, 2]);
      expect(ManufacturerData.parse(bytes), isNull);
    });

    test('isGateway returns true for role 2', () {
      final bytes = Uint8List.fromList([1, 2, 1, 0, 3, 1]);
      final data = ManufacturerData.parse(bytes)!;
      expect(data.isGateway, isTrue);
      expect(data.isEndDevice, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify fails**

Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement manufacturer_data.dart**

```dart
// lib/core/ble/manufacturer_data.dart
import 'dart:typed_data';

/// Parsed manufacturer specific data from BLE advertising — spec §4.5.
class ManufacturerData {
  final int protocolVersion;
  final int role;
  final int networkId;
  final int? edCount;   // GW only
  final int? haRole;    // GW only

  const ManufacturerData({
    required this.protocolVersion,
    required this.role,
    required this.networkId,
    this.edCount,
    this.haRole,
  });

  bool get isGateway => role == 2;
  bool get isEndDevice => role == 1;
  bool get isCC => role == 4;
  bool get isUnprovisioned => role == 0;

  /// Parse manufacturer data payload. Returns null if too short.
  /// Format: [protocol:1][role:1][network_id:2LE][ed_count:1?][ha_role:1?]
  static ManufacturerData? parse(Uint8List bytes) {
    if (bytes.length < 4) return null;

    final bd = ByteData.sublistView(bytes);
    final protocol = bd.getUint8(0);
    final role = bd.getUint8(1);
    final networkId = bd.getUint16(2, Endian.little);

    int? edCount;
    int? haRole;
    if (bytes.length >= 5) edCount = bd.getUint8(4);
    if (bytes.length >= 6) haRole = bd.getUint8(5);

    return ManufacturerData(
      protocolVersion: protocol,
      role: role,
      networkId: networkId,
      edCount: edCount,
      haRole: haRole,
    );
  }
}
```

- [ ] **Step 4: Run test**

Run: `flutter test test/core/ble/manufacturer_data_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/ble/manufacturer_data.dart test/core/ble/manufacturer_data_test.dart
git commit -m "feat: add manufacturer data parser for BLE advertising (spec §4.5)"
```

---

### Task 8: Dependencies Update + Drift Database Setup

**Files:**
- Modify: `pubspec.yaml` — add drift, sqlite3_flutter_libs, shared_preferences, cbor, intl
- Create: `lib/core/data/tables/devices.dart`
- Create: `lib/core/data/tables/alerts.dart`
- Create: `lib/core/data/tables/audit_log.dart`
- Create: `lib/core/data/tables/device_telemetry.dart`
- Create: `lib/core/data/database.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Add to `dependencies`:
```yaml
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  shared_preferences: ^2.3.0
  cbor: ^6.3.0
  intl: ^0.19.0
```

Add to `dev_dependencies`:
```yaml
  drift_dev: ^2.22.0
  build_runner: ^2.4.0
```

Run: `flutter pub get`

- [ ] **Step 2: Create Drift table definitions**

```dart
// lib/core/data/tables/devices.dart
import 'package:drift/drift.dart';

class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get role => text()();
  IntColumn get networkId => integer().nullable()();
  TextColumn get groupName => text().nullable()();
  TextColumn get status => text()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get zone => integer().nullable()();
  TextColumn get firmwareVer => text().nullable()();
  TextColumn get tags => text().nullable()();       // JSON array
  TextColumn get capabilities => text().nullable()(); // JSON
  IntColumn get lastSeen => integer()();
  TextColumn get configJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/data/tables/alerts.dart
import 'package:drift/drift.dart';

class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get severity => text()();
  TextColumn get type => text()();
  TextColumn get message => text().nullable()();
  BlobColumn get rawPayload => blob().nullable()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get resolvedAt => integer().nullable()();
}
```

```dart
// lib/core/data/tables/audit_log.dart
import 'package:drift/drift.dart';

class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userRole => text()();
  TextColumn get action => text()();
  TextColumn get targetDevice => text().nullable()();
  TextColumn get detailBefore => text().nullable()();
  TextColumn get detailAfter => text().nullable()();
  IntColumn get createdAt => integer()();
}
```

```dart
// lib/core/data/tables/device_telemetry.dart
import 'package:drift/drift.dart';

class DeviceTelemetry extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  IntColumn get timestamp => integer()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get zone => integer().nullable()();
  TextColumn get sensorData => text().nullable()(); // JSON

  @override
  List<Set<Column>> get uniqueKeys => [{deviceId, timestamp}];
}
```

- [ ] **Step 3: Create database.dart**

```dart
// lib/core/data/database.dart
import 'package:drift/drift.dart';

import 'tables/devices.dart';
import 'tables/alerts.dart';
import 'tables/audit_log.dart';
import 'tables/device_telemetry.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Devices, Alerts, AuditLog, DeviceTelemetry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 4: Run build_runner to generate database code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Verify build succeeds**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/core/data/ pubspec.yaml pubspec.lock
git commit -m "feat: add Drift database with devices, alerts, audit_log, telemetry tables (spec §7)"
```

---

### Task 9: Device Repository

**Files:**
- Create: `lib/core/data/repositories/device_repository.dart`
- Create: `test/core/data/repositories/device_repository_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/core/data/repositories/device_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/device_repository.dart';

void main() {
  late AppDatabase db;
  late DeviceRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DeviceRepository(db);
  });

  tearDown(() => db.close());

  group('DeviceRepository', () {
    test('upsertDevice inserts new device', () async {
      await repo.upsertDevice(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'GW-Test',
        role: 'gateway',
        status: 'online',
      );
      final devices = await repo.getAllDevices();
      expect(devices, hasLength(1));
      expect(devices.first.name, 'GW-Test');
    });

    test('upsertDevice updates existing device', () async {
      await repo.upsertDevice(id: 'AA:BB', name: 'Old', role: 'gateway', status: 'online');
      await repo.upsertDevice(id: 'AA:BB', name: 'New', role: 'gateway', status: 'offline');
      final devices = await repo.getAllDevices();
      expect(devices, hasLength(1));
      expect(devices.first.name, 'New');
    });

    test('getDevicesByNetwork filters by networkId', () async {
      await repo.upsertDevice(id: 'A', name: 'A', role: 'ed', status: 'online', networkId: 1);
      await repo.upsertDevice(id: 'B', name: 'B', role: 'ed', status: 'online', networkId: 2);
      final net1 = await repo.getDevicesByNetwork(1);
      expect(net1, hasLength(1));
      expect(net1.first.id, 'A');
    });
  });
}
```

- [ ] **Step 2: Run test to verify fails**

Run: `flutter test test/core/data/repositories/device_repository_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement device_repository.dart**

```dart
// lib/core/data/repositories/device_repository.dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/devices.dart';

class DeviceRepository {
  final AppDatabase _db;

  DeviceRepository(this._db);

  Future<List<Device>> getAllDevices() => _db.select(_db.devices).get();

  Future<List<Device>> getDevicesByNetwork(int networkId) =>
    (_db.select(_db.devices)..where((d) => d.networkId.equals(networkId))).get();

  Future<Device?> getDevice(String id) =>
    (_db.select(_db.devices)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<void> upsertDevice({
    required String id,
    required String name,
    required String role,
    required String status,
    int? networkId,
    String? groupName,
    int? rssi,
    int? zone,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.devices).insertOnConflictUpdate(
      DevicesCompanion.insert(
        id: id,
        name: Value(name),
        role: role,
        networkId: Value(networkId),
        groupName: Value(groupName),
        status: status,
        rssi: Value(rssi),
        zone: Value(zone),
        lastSeen: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    (_db.update(_db.devices)..where((d) => d.id.equals(id)))
      .write(DevicesCompanion(
        status: Value(status),
        lastSeen: Value(now),
        updatedAt: Value(now),
      ));
  }
}
```

- [ ] **Step 4: Run test**

Run: `flutter test test/core/data/repositories/device_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/data/repositories/device_repository.dart test/core/data/repositories/
git commit -m "feat: add device repository with upsert and network filter (spec §7.1)"
```

---

### Task 10: Alert and Audit Repositories

**Files:**
- Create: `lib/core/data/repositories/alert_repository.dart`
- Create: `lib/core/data/repositories/audit_repository.dart`
- Create: `test/core/data/repositories/alert_repository_test.dart`
- Create: `test/core/data/repositories/audit_repository_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/core/data/repositories/alert_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/alert_repository.dart';

void main() {
  late AppDatabase db;
  late AlertRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AlertRepository(db);
  });
  tearDown(() => db.close());

  test('insertAlert and getUnresolved', () async {
    await repo.insertAlert(deviceId: 'A', severity: 'warning', type: 'weak_signal', message: 'RSSI -85');
    final alerts = await repo.getUnresolved();
    expect(alerts, hasLength(1));
    expect(alerts.first.type, 'weak_signal');
  });

  test('acknowledge marks alert', () async {
    await repo.insertAlert(deviceId: 'A', severity: 'critical', type: 'offline');
    final alerts = await repo.getUnresolved();
    await repo.acknowledge(alerts.first.id);
    final after = await repo.getUnresolved();
    expect(after, isEmpty);
  });
}
```

```dart
// test/core/data/repositories/audit_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/data/database.dart';
import 'package:ble_qos_app/core/data/repositories/audit_repository.dart';

void main() {
  late AppDatabase db;
  late AuditRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AuditRepository(db);
  });
  tearDown(() => db.close());

  test('log and retrieve audit entries', () async {
    await repo.log(userRole: 'Role-1', action: 'write_ctrl', targetDevice: 'GW-1');
    final entries = await repo.getAll();
    expect(entries, hasLength(1));
    expect(entries.first.action, 'write_ctrl');
  });

  test('getByRole filters entries', () async {
    await repo.log(userRole: 'Role-1', action: 'a');
    await repo.log(userRole: 'Role-2', action: 'b');
    final r1 = await repo.getByRole('Role-1');
    expect(r1, hasLength(1));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/data/repositories/`
Expected: FAIL

- [ ] **Step 3: Implement alert_repository.dart**

```dart
// lib/core/data/repositories/alert_repository.dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/alerts.dart';

class AlertRepository {
  final AppDatabase _db;

  AlertRepository(this._db);

  Future<List<Alert>> getUnresolved() =>
    (_db.select(_db.alerts)
      ..where((a) => a.resolvedAt.isNull())
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
    .get();

  Future<List<Alert>> getRecent({int limit = 50}) =>
    (_db.select(_db.alerts)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  Future<void> insertAlert({
    required String? deviceId,
    required String severity,
    required String type,
    String? message,
  }) async {
    await _db.into(_db.alerts).insert(
      AlertsCompanion.insert(
        deviceId: Value(deviceId),
        severity: severity,
        type: type,
        message: Value(message),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> acknowledge(int id) async {
    (_db.update(_db.alerts)..where((a) => a.id.equals(id)))
      .write(AlertsCompanion(
        acknowledged: const Value(true),
        resolvedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  /// Prune alerts older than duration — spec §7.2 (7 days).
  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (_db.delete(_db.alerts)..where((a) => a.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
```

- [ ] **Step 4: Implement audit_repository.dart**

```dart
// lib/core/data/repositories/audit_repository.dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/audit_log.dart';

class AuditRepository {
  final AppDatabase _db;

  AuditRepository(this._db);

  Future<List<AuditLogData>> getAll({int limit = 100}) =>
    (_db.select(_db.auditLog)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  Future<List<AuditLogData>> getByRole(String userRole, {int limit = 100}) =>
    (_db.select(_db.auditLog)
      ..where((a) => a.userRole.equals(userRole))
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit))
    .get();

  Future<void> log({
    required String userRole,
    required String action,
    String? targetDevice,
    String? detailBefore,
    String? detailAfter,
  }) async {
    await _db.into(_db.auditLog).insert(
      AuditLogCompanion.insert(
        userRole: userRole,
        action: action,
        targetDevice: Value(targetDevice),
        detailBefore: Value(detailBefore),
        detailAfter: Value(detailAfter),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Prune entries older than duration — spec §7.2 (90 days).
  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    return (_db.delete(_db.auditLog)..where((a) => a.createdAt.isSmallerThanValue(cutoff))).go();
  }
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/core/data/repositories/`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/data/repositories/ test/core/data/repositories/
git commit -m "feat: add alert and audit repositories with prune support (spec §7)"
```

---

### Task 11: GoRouter Setup + Dark Theme Integration

**Files:**
- Modify: `lib/main.dart` — replace MaterialApp.routes with GoRouter + AppTheme.dark

- [ ] **Step 1: Rewrite main.dart with GoRouter and dark theme**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/device/device_screen.dart';
import 'features/provisioning/provisioning_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/audit/audit_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const ScannerScreen()),
    GoRoute(path: '/device/:id', builder: (_, state) =>
      DeviceScreen(deviceId: state.pathParameters['id']!)),
    GoRoute(path: '/provisioning/:id', builder: (_, state) =>
      ProvisioningScreen(deviceId: state.pathParameters['id']!)),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/audit', builder: (_, __) => const AuditScreen()),
  ],
);

void main() {
  runApp(const ProviderScope(child: BleQosApp()));
}

class BleQosApp extends StatelessWidget {
  const BleQosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BLE QoS Monitor',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

Note: ScannerScreen, DeviceScreen, ProvisioningScreen, AuditScreen are stubs at this point — create minimal placeholder widgets so the app compiles.

- [ ] **Step 2: Create placeholder screens**

Create minimal stubs for `scanner_screen.dart`, `device_screen.dart`, `provisioning_screen.dart`, `audit_screen.dart` — each just a `Scaffold` with `AppBar` title.

- [ ] **Step 3: Update widget test**

Update `test/widget_test.dart` to use the new `BleQosApp` widget.

- [ ] **Step 4: Run flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: No errors, all tests pass

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/features/scanner/ lib/features/device/ lib/features/provisioning/ lib/features/audit/ test/widget_test.dart
git commit -m "feat: integrate GoRouter + dark tech theme, add screen stubs (spec §2, §8)"
```

---

### Task 12: Scanner Screen — Fleet Dashboard with EMA + Stale/Offline

**Files:**
- Modify: `lib/core/ble/ble_scanner.dart` — add EMA, stale/offline, duty cycle
- Modify: `lib/core/ble/ble_models.dart` — expand ScannedDevice
- Create: `lib/features/scanner/scanner_screen.dart` — full Fleet Overview
- Create: `lib/features/scanner/fleet_summary.dart` — stat cards
- Create: `lib/features/scanner/scan_device_tile.dart` — device tile

- [ ] **Step 1: Expand ScannedDevice model with EMA, status, manufacturer data**

Add to `ble_models.dart`:
- `double smoothedRssi` (EMA)
- `DeviceStatus status` enum: `online`, `stale`, `offline`
- `DateTime lastSeen`
- `ManufacturerData? mfgData`
- `String? alias` (user-set name)

- [ ] **Step 2: Add EMA + stale/offline logic to BleScanner**

In `ble_scanner.dart`:
- EMA: `smoothed = 0.3 * new + 0.7 * prev` (spec §4.1)
- 10s no adv → stale, 30s → offline (spec §4.1)
- Duty cycle: scan 2s / pause 3s via `Timer` (spec §4.1)
- Parse `advertisementData.manufacturerData` for ManufacturerData

- [ ] **Step 3: Implement Fleet Dashboard screen**

`scanner_screen.dart` — Fleet summary cards (online/warn/offline counts) + search bar + device list grouped by network_id

- [ ] **Step 4: Implement fleet_summary.dart and scan_device_tile.dart**

Stat cards with AppColors.success/warning/error. Device tile showing name, RSSI, zone badge, status indicator.

- [ ] **Step 5: Run flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/ble/ble_scanner.dart lib/core/ble/ble_models.dart lib/features/scanner/
git commit -m "feat: scanner overhaul — EMA smoothing, stale/offline tracking, fleet dashboard (spec §4)"
```

---

### Task 13: Device Screen — Capability-Driven Tab Layout

**Files:**
- Rewrite: `lib/features/device/device_screen.dart` — tabs from capabilities
- Create: `lib/features/device/dashboard/dashboard_tab.dart`
- Create: `lib/features/device/control/control_tab.dart`
- Create: `lib/features/device/ha/ha_tab.dart`
- Create: `lib/features/device/admin/admin_tab.dart`

- [ ] **Step 1: Implement DeviceScreen with dynamic tabs**

Use `CapabilityNegotiator.negotiate()` result to build `TabBar` dynamically. Each tab maps to a capability handler (spec §5.3).

- [ ] **Step 2: Implement DashboardTab**

Show RSSI, Zone, PHY, TX, PDR, Interval, Latency metrics using `MetricCard` widgets. Subscribe to STATUS + METRICS notify streams.

- [ ] **Step 3: Implement ControlTab**

QoS profile selector, CTRL write buttons. Permission-gated by `PermissionGuard.canWrite()`.

- [ ] **Step 4: Implement HaTab**

HA status display (spec §10): Active/Standby role, epoch, heartbeat, failover history.

- [ ] **Step 5: Implement AdminTab**

Engineer-only (spec §11): ENG_UNLOCK, CTRL read, GW_CFG editor, CMD console, PIN management. Replaces old `EngineerScreen`.

- [ ] **Step 6: Run flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/device/
git commit -m "feat: capability-driven device screen with Dashboard/Control/HA/Admin tabs (spec §5, §10, §11)"
```

---

### Task 14: Provisioning Screen + Audit Screen

**Files:**
- Rewrite: `lib/features/provisioning/provisioning_screen.dart`
- Rewrite: `lib/features/audit/audit_screen.dart`

- [ ] **Step 1: Implement ProvisioningScreen**

Flow per spec §9: role selector (GW/ED/CC), network_id input, device name input, ROLE write button with reboot warning. Permission-gated for engineer role.

- [ ] **Step 2: Implement AuditScreen**

Table/list view of audit log entries (spec §12). Filter by role, search. Role-1 sees own entries, Role-2 sees all. Export CSV button (Phase 2 stub).

- [ ] **Step 3: Run flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/provisioning/ lib/features/audit/
git commit -m "feat: add provisioning flow and audit log screen (spec §9, §12)"
```

---

### Task 15: Cleanup — Remove Deprecated Screens + Update CI

**Files:**
- Delete: `lib/features/home/gw_home_screen.dart`
- Delete: `lib/features/home/ed_home_screen.dart`
- Delete: `lib/features/device_list/device_list_screen.dart`
- Delete: `lib/features/device_list/device_tile.dart`
- Delete: `lib/features/patrol/patrol_screen.dart`
- Delete: `lib/features/engineer/engineer_screen.dart`
- Delete: `lib/features/installer/installer_screen.dart`
- Delete: `lib/core/domain/role_policy.dart` (replaced by permission_guard)
- Delete: `lib/core/domain/unlock_session.dart` (replaced by auth_session)
- Delete: `lib/core/providers/role_provider.dart` (replaced by auth_provider)
- Modify: `.github/workflows/ci.yml` — add `dart run build_runner build` before analyze

- [ ] **Step 1: Delete deprecated files**

Remove all old screens and domain files that have been replaced.

- [ ] **Step 2: Update CI workflow**

Add build_runner step before `flutter analyze`:
```yaml
- run: dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Remove old tests that reference deleted files**

Update or remove tests in `test/role_policy_test.dart`, `test/unlock_session_test.dart` that reference old APIs.

- [ ] **Step 4: Run full test suite**

Run: `flutter analyze && flutter test`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated v1 screens and domain models, update CI"
```

---

## Execution Summary

| Task | Layer | Description |
|------|-------|-------------|
| 1 | Domain | Dark tech theme colors + ThemeData |
| 2 | Domain | PIN validator with lockout |
| 3 | Domain | Auth session with dual timeouts |
| 4 | Domain | Permission guard matrix |
| 5 | Domain | Capability model + registry |
| 6 | Domain | Capability negotiator |
| 7 | Domain | Manufacturer data parser |
| 8 | Infra | Drift database + tables |
| 9 | Infra | Device repository |
| 10 | Infra | Alert + audit repositories |
| 11 | UI | GoRouter + dark theme integration |
| 12 | UI | Scanner Fleet Dashboard |
| 13 | UI | Capability-driven device screen |
| 14 | UI | Provisioning + audit screens |
| 15 | Chore | Cleanup deprecated code + CI update |
