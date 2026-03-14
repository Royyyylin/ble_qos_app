import '../gatt/gatt_uuids.dart';

/// App-side user roles (not firmware ROLE).
/// See: docs/current/app_role_pages.md §2
enum AppRole {
  patrol,
  installer,
  engineer,
}

/// Permission check for GATT write operations per app role.
/// Source of truth: docs/current/app_role_pages.md §2.2
class RolePolicy {
  RolePolicy._();

  /// Characteristics writable by each role.
  static const _writable = <AppRole, Set<String>>{
    AppRole.patrol: {},
    AppRole.installer: {
      GattUuids.role,
      GattUuids.cmd, // CMD 0x02 SET_MAX_ED only
    },
    AppRole.engineer: {
      GattUuids.role,
      GattUuids.cmd,
      GattUuids.ctrl,
      GattUuids.mode,
      GattUuids.gwCfg,
      GattUuids.gwCfgVnd,
      GattUuids.ping,
      GattUuids.engUnlock,
      GattUuids.engPinSet,
    },
  };

  static bool canWrite(AppRole role, String characteristicUuid) {
    return _writable[role]?.contains(characteristicUuid) ?? false;
  }
}
