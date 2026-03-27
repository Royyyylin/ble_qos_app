# BLE QoS App — Current State

**最後更新：** 2026-03-28

## 架構決策 — 6/6 全部定案 + 架構對齊完成

詳見 `docs/architecture/APP_ARCHITECTURE.md`。

## Prototype 進度

- [x] Design Spec 全面實作 + Code review 修正
- [x] CMD_V2/CMD_RESULT/ROSTER_LIST + CmdV2Service
- [x] CAPS_V2 CBOR parser + HA standalone mode
- [x] FW_VERSION + DEVICE_INFO + GW_CFG_VERSION
- [x] Dashboard polling 2s + last valid + Throughput N/A
- [x] Roster MAC matching + Connect/ConnectAll/Remove
- [x] Auth countdown warning + Lock Now + PIN secure storage
- [x] Persistent DB (NativeDatabase File)
- [x] BleError 7-type taxonomy + classified error screen
- [x] BLE lifecycle: 2-stage TTL + disconnect on leave/background
- [x] Maestro 安裝 + Semantics identifiers
- [x] 241 tests, 0 analyze warnings
- [x] Device Alias: DB schema v3 + identity service + GATT fallback + rename dialog (Central authority)
- [x] HTML Prototype: Scanner + Device Screen (5 tabs) + Roster per-ED metrics (方案 B)
- [x] App Scope 定案: `docs/specs/app-scope.md` — 邊界、責任、契約
- [x] Profile-aware state models: `lib/core/telemetry/` — TelemetryValueState 5 態 + MetricValue + TelemetrySnapshot + EdDeviceState + SyncState + CentralAuthState

## Firmware P0 同步（2026-03-28）

- 韌體已完成 P0/P1 payload 分級 + golden byte tests + P1 metrics trial integration
- 下一步：P0 event-driven trial（heartbeat/disconnect/reconnect）
- **App 假設已同步：**
  - `msg_seq` 不是全 family 共用強一致序列
  - `P0 ed_hash(2B)` 不可當 canonical identity
  - `boot_id = reset_count` 仍是暫代方案
  - P0 缺欄位 ≠ error/degraded/down（App 用 `TelemetryValueState.sparse`）
  - 不假設所有 payload 有完整時間戳或完整 identity

## 下一步

1. PR merge: `feat/prototype-roster-dashboard-update` → main
2. HTML prototype → Flutter 遷移
3. HTML prototype → Flutter 遷移
4. 實機驗證 persistent DB
5. Central sync client 對接（等 Central A3 auth 完成後）

## Backlog

- Provisioning networkId（韌體不支援）
- Android Play Data safety / iOS App Store
- 更多 widget Semantics identifier

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17 / Maestro 2.3.0 / Claude Code 2.1.84
- 韌體 1.2.0+0（PR #62-#75 merged，4 DK flash）
