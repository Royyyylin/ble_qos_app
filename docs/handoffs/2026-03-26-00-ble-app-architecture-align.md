---
date: 2026-03-26
time: "00:30"
type: feature + architecture + debugging + infrastructure
---

# EOD Handoff — 2026-03-26 00:30

## Summary

BLE QoS App 完成架構對齊：6 known issues 全修、CAPS_V2 CBOR 整合、persistent DB、BleError 分類、Maestro 安裝、token 優化研究。韌體 13 個 PR merged + 4 DK flash。

## Modified Files

### App repo（`ble_qos_app`，branch: `feat/fix-6-known-issues-from-docs-architectur-20260324_004405`）

**Core 層：**
- `lib/core/providers/metrics_provider.dart` — STATUS 2s polling + last valid value + CAPS_V2 provider + DEVICE_INFO 30s refresh
- `lib/core/providers/database_provider.dart` — NativeDatabase.memory() → File persistent
- `lib/core/providers/ed_roster_provider.dart` — MAC-based matching + filter duplicates
- `lib/core/ble/ble_connector.dart` — per-step timeout (5s/3s) + BleError lastError
- `lib/core/ble/ble_scanner.dart` — TTL 30s stale / 120s evict
- `lib/core/ble/ble_models.dart` — TTL thresholds updated
- `lib/core/gatt/gatt_structs.dart` — QosCtrl byte layout fix + QosEvtV1 seq uint8
- `lib/core/gatt/gatt_uuids.dart` — CAPS_V2 UUID + remove orphan edCount/edList
- `lib/core/gatt/caps_v2.dart` — CBOR parser (NEW)
- `lib/core/gatt/cmd_v2_service.dart` — eng_unlock scope fix + Completer nullable
- `lib/core/auth/auth_session.dart` — countdown warning + lastPin storage
- `lib/core/auth/pin_storage.dart` — flutter_secure_storage (NEW)
- `lib/core/error/ble_error.dart` — 7-type error taxonomy (NEW)
- `lib/core/data/audit_logger.dart` — audit wiring (NEW)

**Feature 層：**
- `lib/features/device/device_screen.dart` — ConsumerStatefulWidget + background disconnect + session warning banner + remove showControlTab/showAdminTab
- `lib/features/device/dashboard/dashboard_tab.dart` — 0-value "--" + Throughput N/A + metricsStreamProvider
- `lib/features/device/roster/ed_roster_tab.dart` — Connect/ConnectAll/Remove + MAC dedup + confirmation dialog
- `lib/features/device/ha/ha_tab.dart` — CAPS_V2 ha_state standalone mode
- `lib/features/device/control/control_tab.dart` — ROLE selector + read current STATUS for phy/tx
- `lib/features/scanner/scanner_screen.dart` — RouteAware scan restart + Semantics
- `lib/features/scanner/scan_device_tile.dart` — Semantics identifier
- `lib/features/settings/settings_screen.dart` — PIN storage + audit logging
- `lib/main.dart` — initDatabasePath + remove route hardcode

**刪除：**
- `lib/core/gatt/gatt_cmd_service.dart` — legacy CMD (replaced by CmdV2)
- `lib/core/capability/compat_matrix.dart` — unused (UI uses CapabilityRegistry)

**Skill：**
- `~/.claude/skills/app-verify/SKILL.md` — Maestro hierarchy 優先 + 除錯優先順序
- `~/.claude/skills/app-verify/references/lessons-learned.md`
- `~/.claude/skills/app-verify/references/maestro-roadmap.md`
- `.claude/rules/lessons-ble.md` — 8 條 BLE 開發硬規則 (NEW)

**設定：**
- `~/.claude/settings.json` — subagent sonnet + disable 2 plugins

## Key Changes

1. **架構對齊** — 用兩個 Opus subagent 比對架構 vs 實作差距，找出 11 項問題並修復
2. **CAPS_V2 CBOR** — 韌體加了 ha_state key，App 讀取後 HA tab 顯示 Standalone Mode
3. **Critical wire format fix** — QosCtrl byte layout 全部錯位（tpMode 被跳過），QosEvtV1 seq 用 uint16 讀 uint8
4. **Persistent DB** — 從 memory-only 改成 file-based，裝置 identity 跨 session 保留
5. **Token 優化研究** — 截圖佔 41% token，Maestro hierarchy 省 10x

## Immediate

1. 韌體 STATUS characteristic 長時間運行後回 0 — 等韌體 AI 診斷
2. PR #10 CI pass 後 merge 到 main
3. 實機驗證 persistent DB（重啟 App 後裝置 identity 是否保留）

## Backlog

- PinValidator 整合（Phase 2，等韌體 ENG_UNLOCK 回報 success/fail）
- Provisioning networkId 寫入（韌體不支援）
- Maestro YAML flow 取代 adb tap
- 更多 widget 加 Semantics identifier

## Key Insights

- Maestro hierarchy 比截圖 crop 可靠 10 倍，且省 token — 已整合到 app-verify skill
- 架構文件 vs 實作比對用 subagent 平行跑最有效率
- 韌體 STATUS 間歇回 0 是韌體行為，App 用 last valid value 保留
- token 最大殺手是截圖（41%），其次是 plugins 常駐（21%）

## Environment Notes

- Maestro 2.3.0 安裝完成（需要 JAVA_HOME）
- Claude Code 2.1.84
- App: 237 tests, 0 analyze warnings
- 韌體 PR #62-#75 全 merged，4 DK flash
- settings.json: subagent=sonnet, disabled agent-sdk-dev + claude-code-setup
