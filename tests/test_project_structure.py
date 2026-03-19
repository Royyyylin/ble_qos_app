"""Validate BLE QoS App project structure and implementation completeness."""
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _exists(rel: str) -> bool:
    return (ROOT / rel).exists()


def _file_contains(rel: str, needle: str) -> bool:
    path = ROOT / rel
    if not path.exists():
        return False
    return needle in path.read_text()


# ---------------------------------------------------------------------------
# Task 1: Dark Tech Theme
# ---------------------------------------------------------------------------

class TestTheme:
    def test_app_colors_exists(self):
        assert _exists("lib/core/theme/app_colors.dart")

    def test_app_theme_exists(self):
        assert _exists("lib/core/theme/app_theme.dart")

    def test_app_colors_has_background(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "background")

    def test_app_colors_has_primary(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "primary")

    def test_app_colors_has_surface(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "surface")

    def test_app_colors_has_error(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "error")

    def test_app_colors_has_success(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "success")

    def test_app_colors_has_warning(self):
        assert _file_contains("lib/core/theme/app_colors.dart", "warning")

    def test_theme_uses_dark_brightness(self):
        assert _file_contains("lib/core/theme/app_theme.dart", "Brightness.dark")


# ---------------------------------------------------------------------------
# Task 2: PIN Validator
# ---------------------------------------------------------------------------

class TestPinValidator:
    def test_file_exists(self):
        assert _exists("lib/core/auth/pin_validator.dart")

    def test_has_lockout(self):
        assert _file_contains("lib/core/auth/pin_validator.dart", "isLockedOut")

    def test_has_validate(self):
        assert _file_contains("lib/core/auth/pin_validator.dart", "validate")

    def test_has_max_attempts(self):
        assert _file_contains("lib/core/auth/pin_validator.dart", "maxAttempts")

    def test_test_exists(self):
        assert _exists("test/core/auth/pin_validator_test.dart")


# ---------------------------------------------------------------------------
# Task 3: Auth Session
# ---------------------------------------------------------------------------

class TestAuthSession:
    def test_file_exists(self):
        assert _exists("lib/core/auth/auth_session.dart")

    def test_has_three_roles(self):
        content = (ROOT / "lib/core/auth/auth_session.dart").read_text()
        assert "normal" in content
        assert "maintenance" in content
        assert "engineer" in content

    def test_has_idle_timeout(self):
        assert _file_contains("lib/core/auth/auth_session.dart", "idleTimeout")

    def test_has_absolute_timeout(self):
        assert _file_contains("lib/core/auth/auth_session.dart", "absoluteTimeout")

    def test_has_elevate(self):
        assert _file_contains("lib/core/auth/auth_session.dart", "elevate")

    def test_has_demote(self):
        assert _file_contains("lib/core/auth/auth_session.dart", "demote")

    def test_test_exists(self):
        assert _exists("test/core/auth/auth_session_test.dart")


# ---------------------------------------------------------------------------
# Task 4: Permission Guard
# ---------------------------------------------------------------------------

class TestPermissionGuard:
    def test_file_exists(self):
        assert _exists("lib/core/auth/permission_guard.dart")

    def test_has_gatt_action_enum(self):
        assert _file_contains("lib/core/auth/permission_guard.dart", "GattAction")

    def test_has_can_read(self):
        assert _file_contains("lib/core/auth/permission_guard.dart", "canRead")

    def test_has_can_write(self):
        assert _file_contains("lib/core/auth/permission_guard.dart", "canWrite")

    def test_has_requires_confirmation(self):
        assert _file_contains("lib/core/auth/permission_guard.dart", "requiresConfirmation")

    def test_test_exists(self):
        assert _exists("test/core/auth/permission_guard_test.dart")


# ---------------------------------------------------------------------------
# Task 5: Capability Model + Registry
# ---------------------------------------------------------------------------

class TestCapabilitySystem:
    def test_model_exists(self):
        assert _exists("lib/core/capability/capability_model.dart")

    def test_registry_exists(self):
        assert _exists("lib/core/capability/capability_registry.dart")

    def test_model_has_capability_class(self):
        assert _file_contains("lib/core/capability/capability_model.dart", "class Capability")

    def test_registry_has_handler(self):
        assert _file_contains("lib/core/capability/capability_registry.dart", "hasHandler")

    def test_registry_has_fallback_for_role(self):
        assert _file_contains("lib/core/capability/capability_registry.dart", "fallbackForRole")

    def test_model_test_exists(self):
        assert _exists("test/core/capability/capability_model_test.dart")

    def test_registry_test_exists(self):
        assert _exists("test/core/capability/capability_registry_test.dart")


# ---------------------------------------------------------------------------
# Task 6: Capability Negotiator
# ---------------------------------------------------------------------------

class TestCapabilityNegotiator:
    def test_file_exists(self):
        assert _exists("lib/core/capability/capability_negotiator.dart")

    def test_has_negotiate(self):
        assert _file_contains("lib/core/capability/capability_negotiator.dart", "negotiate")

    def test_has_negotiation_result(self):
        assert _file_contains("lib/core/capability/capability_negotiator.dart", "NegotiationResult")

    def test_test_exists(self):
        assert _exists("test/core/capability/capability_negotiator_test.dart")


# ---------------------------------------------------------------------------
# Task 7: Manufacturer Data Parser
# ---------------------------------------------------------------------------

class TestManufacturerData:
    def test_file_exists(self):
        assert _exists("lib/core/ble/manufacturer_data.dart")

    def test_has_parse(self):
        assert _file_contains("lib/core/ble/manufacturer_data.dart", "parse")

    def test_has_is_gateway(self):
        assert _file_contains("lib/core/ble/manufacturer_data.dart", "isGateway")

    def test_test_exists(self):
        assert _exists("test/core/ble/manufacturer_data_test.dart")


# ---------------------------------------------------------------------------
# Task 8: Drift Database
# ---------------------------------------------------------------------------

class TestDriftDatabase:
    def test_database_exists(self):
        assert _exists("lib/core/data/database.dart")

    def test_devices_table(self):
        assert _exists("lib/core/data/tables/devices.dart")

    def test_alerts_table(self):
        assert _exists("lib/core/data/tables/alerts.dart")

    def test_audit_log_table(self):
        assert _exists("lib/core/data/tables/audit_log.dart")

    def test_device_telemetry_table(self):
        assert _exists("lib/core/data/tables/device_telemetry.dart")

    def test_generated_file_exists(self):
        assert _exists("lib/core/data/database.g.dart")


# ---------------------------------------------------------------------------
# Task 9: Device Repository
# ---------------------------------------------------------------------------

class TestDeviceRepository:
    def test_file_exists(self):
        assert _exists("lib/core/data/repositories/device_repository.dart")

    def test_has_upsert(self):
        assert _file_contains("lib/core/data/repositories/device_repository.dart", "upsertDevice")

    def test_has_get_by_network(self):
        assert _file_contains("lib/core/data/repositories/device_repository.dart", "getDevicesByNetwork")

    def test_test_exists(self):
        assert _exists("test/core/data/repositories/device_repository_test.dart")


# ---------------------------------------------------------------------------
# Task 10: Alert + Audit Repositories
# ---------------------------------------------------------------------------

class TestAlertAuditRepositories:
    def test_alert_repo_exists(self):
        assert _exists("lib/core/data/repositories/alert_repository.dart")

    def test_audit_repo_exists(self):
        assert _exists("lib/core/data/repositories/audit_repository.dart")

    def test_alert_has_insert(self):
        assert _file_contains("lib/core/data/repositories/alert_repository.dart", "insertAlert")

    def test_alert_has_acknowledge(self):
        assert _file_contains("lib/core/data/repositories/alert_repository.dart", "acknowledge")

    def test_audit_has_log(self):
        assert _file_contains("lib/core/data/repositories/audit_repository.dart", "log")

    def test_alert_test_exists(self):
        assert _exists("test/core/data/repositories/alert_repository_test.dart")

    def test_audit_test_exists(self):
        assert _exists("test/core/data/repositories/audit_repository_test.dart")


# ---------------------------------------------------------------------------
# Task 11: GoRouter + Dark Theme
# ---------------------------------------------------------------------------

class TestMainApp:
    def test_main_exists(self):
        assert _exists("lib/main.dart")

    def test_uses_go_router(self):
        assert _file_contains("lib/main.dart", "GoRouter")

    def test_uses_dark_theme(self):
        assert _file_contains("lib/main.dart", "AppTheme.dark")

    def test_uses_provider_scope(self):
        assert _file_contains("lib/main.dart", "ProviderScope")

    def test_routes_defined(self):
        content = (ROOT / "lib/main.dart").read_text()
        assert "/device/" in content
        assert "/provisioning/" in content
        assert "/audit" in content


# ---------------------------------------------------------------------------
# Task 12: Scanner Screen
# ---------------------------------------------------------------------------

class TestScannerScreen:
    def test_scanner_screen_exists(self):
        assert _exists("lib/features/scanner/scanner_screen.dart")

    def test_fleet_summary_exists(self):
        assert _exists("lib/features/scanner/fleet_summary.dart")

    def test_scan_device_tile_exists(self):
        assert _exists("lib/features/scanner/scan_device_tile.dart")

    def test_ble_models_has_ema(self):
        assert _file_contains("lib/core/ble/ble_models.dart", "smoothedRssi")

    def test_ble_models_has_device_status(self):
        assert _file_contains("lib/core/ble/ble_models.dart", "DeviceStatus")

    def test_scanner_has_duty_cycle(self):
        assert _file_contains("lib/core/ble/ble_scanner.dart", "dutyCycle") or \
               _file_contains("lib/core/ble/ble_scanner.dart", "_scanDuration")


# ---------------------------------------------------------------------------
# Task 13: Device Screen
# ---------------------------------------------------------------------------

class TestDeviceScreen:
    def test_device_screen_exists(self):
        assert _exists("lib/features/device/device_screen.dart")

    def test_dashboard_tab_exists(self):
        assert _exists("lib/features/device/dashboard/dashboard_tab.dart")

    def test_control_tab_exists(self):
        assert _exists("lib/features/device/control/control_tab.dart")

    def test_ha_tab_exists(self):
        assert _exists("lib/features/device/ha/ha_tab.dart")

    def test_admin_tab_exists(self):
        assert _exists("lib/features/device/admin/admin_tab.dart")

    def test_device_screen_has_tabs(self):
        assert _file_contains("lib/features/device/device_screen.dart", "TabBar")

    def test_device_screen_test_exists(self):
        assert _exists("test/features/device/device_screen_test.dart")


# ---------------------------------------------------------------------------
# Task 14: Provisioning + Audit Screens
# ---------------------------------------------------------------------------

class TestProvisioningAudit:
    def test_provisioning_screen_exists(self):
        assert _exists("lib/features/provisioning/provisioning_screen.dart")

    def test_audit_screen_exists(self):
        assert _exists("lib/features/audit/audit_screen.dart")

    def test_provisioning_test_exists(self):
        assert _exists("test/features/provisioning/provisioning_screen_test.dart")


# ---------------------------------------------------------------------------
# Task 15: Cleanup
# ---------------------------------------------------------------------------

class TestCleanup:
    def test_deprecated_gw_home_removed(self):
        assert not _exists("lib/features/home/gw_home_screen.dart")

    def test_deprecated_ed_home_removed(self):
        assert not _exists("lib/features/home/ed_home_screen.dart")

    def test_deprecated_device_list_removed(self):
        assert not _exists("lib/features/device_list/device_list_screen.dart")

    def test_deprecated_patrol_removed(self):
        assert not _exists("lib/features/patrol/patrol_screen.dart")

    def test_deprecated_engineer_removed(self):
        assert not _exists("lib/features/engineer/engineer_screen.dart")

    def test_deprecated_installer_removed(self):
        assert not _exists("lib/features/installer/installer_screen.dart")

    def test_deprecated_role_policy_removed(self):
        assert not _exists("lib/core/domain/role_policy.dart")

    def test_deprecated_unlock_session_removed(self):
        assert not _exists("lib/core/domain/unlock_session.dart")


# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

class TestDependencies:
    def test_pubspec_has_drift(self):
        assert _file_contains("pubspec.yaml", "drift:")

    def test_pubspec_has_cbor(self):
        assert _file_contains("pubspec.yaml", "cbor:")

    def test_pubspec_has_shared_preferences(self):
        assert _file_contains("pubspec.yaml", "shared_preferences:")

    def test_pubspec_has_go_router(self):
        assert _file_contains("pubspec.yaml", "go_router:")

    def test_pubspec_has_riverpod(self):
        assert _file_contains("pubspec.yaml", "flutter_riverpod:")

    def test_pubspec_has_crypto(self):
        assert _file_contains("pubspec.yaml", "crypto:")


# ---------------------------------------------------------------------------
# GATT UUIDs
# ---------------------------------------------------------------------------

class TestGattUuids:
    def test_gatt_uuids_exists(self):
        assert _exists("lib/core/gatt/gatt_uuids.dart")

    def test_has_capability_uuid(self):
        assert _file_contains("lib/core/gatt/gatt_uuids.dart", "capability") or \
               _file_contains("lib/core/gatt/gatt_uuids.dart", "6f8a9c19")


# ---------------------------------------------------------------------------
# Files that MUST NOT be modified (existence check)
# ---------------------------------------------------------------------------

class TestPreservedFiles:
    def test_gatt_structs_preserved(self):
        assert _exists("lib/core/gatt/gatt_structs.dart")

    def test_gatt_peer_role_preserved(self):
        assert _exists("lib/core/gatt/gatt_peer_role.dart")

    def test_ble_reconnect_preserved(self):
        assert _exists("lib/core/ble/ble_reconnect.dart")
