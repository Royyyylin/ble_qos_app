# App 核心 Local/UI State 清單

[← 回 app-scope.md](../app-scope.md)

---

## Session / Auth

| State | 類型 | 說明 |
|-------|------|------|
| `current_role` | `AuthRole` enum | normal / maintenance / engineer |
| `session_state` | `AuthSession` | idle timer, absolute timer, warning countdown |
| `last_pin` | in-memory only | secure storage 存 hash |

## UI State

| State | 類型 | 說明 |
|-------|------|------|
| `selected_device_id` | `String` (StableId) | 目前連線的裝置 |
| `active_tab` | enum | Dashboard / Roster / HA / Control / Admin |
| `search_query` | `String` | Scanner search filter |
| `scanning` | `bool` | scan lifecycle |
| `connecting` | `bool` | connection overlay |
| `filter_state` / `sort_state` | local | Scanner list order |

## Cached Data

| Cache | 來源 | 用途 |
|-------|------|------|
| `DeviceIdentities` | DB table | stableId ↔ MAC + alias + central_ref + revision |
| `ed_roster_cache` | GATT ROSTER_LIST | firmware roster snapshot |
| `telemetry_snapshot` | GATT STATUS/METRICS polling | last valid per-ED metrics |
| `alias_cache` | `DeviceIdentityService._aliases` | in-memory stableId → alias |
| `discovered_devices` | `scanResultsProvider` | BLE scan results |
| `caps_v2_cache` | GATT CAPS_V2 | capability + HA state |

## Edit / Command Intents

| Intent | 狀態 | 說明 |
|--------|------|------|
| `pending_alias_edits` | future: PendingAliasOps table | 待同步到 Central |
| `pending_connect` | CMD_V2 in-flight | CONNECT_ED / DISCONNECT_ED |
| `pending_roster_ops` | CMD_V2 in-flight | ROSTER_ADD / ROSTER_REMOVE |

## Presentation Metadata

| Flag | 用途 |
|------|------|
| `stale_flags` | STATUS polling last valid retention |
| `loading_state` | per-provider AsyncValue loading/error |
| `empty_state` | no devices / no HA pair / empty slots |
| `permission_denied_state` | SnackBar on unauthorized action |
