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
| `telemetry_snapshot` | GATT STATUS/METRICS polling | last valid per-ED metrics（**欄位可 nullable — P0 sparse**） |
| `alias_cache` | `DeviceIdentityService._aliases` | in-memory stableId → alias |
| `discovered_devices` | `scanResultsProvider` | BLE scan results |
| `caps_v2_cache` | GATT CAPS_V2 | capability + HA state |

## Telemetry Value State（Profile-Aware）

每個 telemetry 欄位的值必須能區分以下狀態，不可混為一談：

| State | 語意 | UI 顯示 |
|-------|------|---------|
| `present` | 有值，來自 P1 完整 payload | 正常顯示 + 色彩分級 |
| `sparse` | 欄位缺失，來自 P0 sparse profile | `--` 或 `sparse` badge |
| `stale` | 曾有值但已超過 freshness threshold | 灰化 + 時間戳 |
| `unknown` | 從未收到該欄位 | `--` |
| `not_synced` | Central 尚未同步到此裝置的資料 | `--` + sync indicator |

**規則：** `sparse` ≠ `stale` ≠ `unknown` ≠ `error`。P0 缺欄位是正常行為，不是錯誤。

## Payload Profile State

| State | 類型 | 說明 |
|-------|------|------|
| `last_payload_profile` | `enum?` (P0/P1/P2/null) | 該 ED 最近收到的 payload 來自哪個 profile |
| `profile_since` | `DateTime?` | 從何時開始收到該 profile 的資料 |

App 內部 model 必須能承接 profile 概念，即使 UI 先不顯示 profile 名稱。

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
| `sparse_profile_flags` | per-ED: 是否最近收到 P0 sparse payload |
