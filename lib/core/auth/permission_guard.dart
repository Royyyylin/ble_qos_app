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
