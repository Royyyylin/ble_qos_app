# EOD Handoff — 2026-03-22 11:10

**Date**: 2026-03-22
**Session Type**: feature + bugfix + verification
**Repo(s) Affected**: ble_qos_app

## Summary

實作 GW Roster ED 選擇功能（CMD 0x03/0x04 Connect/Disconnect），修復 8 個 code review bug（含 3 個 Critical：MAC byte order、EVT filter、disconnect slot），整合 V2 設計的 Pass/Fail 門檻 + Tooltip 系統，完成 7/7 實機驗證。建立 app-verify skill。

## Modified Files

### 新功能
- `lib/core/providers/scan_provider.dart` — 全域 scan 結果 provider
- `lib/core/providers/ed_roster_provider.dart` — ED roster + ED_LIST address matching
- `lib/core/providers/database_provider.dart` — DB provider + data retention pruning
- `lib/core/gatt/gatt_cmd_service.dart` — CMD 0x03/0x04 高層 API
- `lib/core/gatt/gatt_structs.dart` — CmdCode 0x03/0x04 payload + EvtInfoId + EdListEntry parser
- `lib/core/gatt/gatt_uuids.dart` — 新增 edList, edCount UUID
- `lib/core/domain/health_threshold.dart` — Pass/Fail 門檻判定
- `lib/features/device/roster/ed_roster_tab.dart` — Roster tab 實作 + Connect/Disconnect 按鈕
- `lib/widgets/info_tooltip.dart` — ⓘ tooltip bottom sheet
- `lib/data/tooltip_content.dart` — 30+ tooltip 常數

### Bug 修復
- `lib/features/device/roster/ed_roster_tab.dart` — F1 EVT filter、F2 disconnect slot、F8 dead code
- `lib/core/gatt/gatt_structs.dart` — F3 MAC byte order、F4 ED_LIST address
- `lib/core/auth/auth_session.dart` — F5 ChangeNotifier reactive
- `lib/core/providers/auth_provider.dart` — F5 ChangeNotifierProvider
- `lib/features/settings/settings_screen.dart` — F6 PIN 長度 + PIN dialog
- `lib/features/scanner/scanner_screen.dart` — F9 Settings 入口

### 既有功能改進
- `lib/features/device/dashboard/dashboard_tab.dart` — Pass/Fail 顏色 + tooltip + metric reorder
- `lib/features/device/control/control_tab.dart` — Profile selector (FAST/BALANCED/ROBUST)
- `lib/features/audit/audit_screen.dart` — 接線 auditEntriesProvider
- `lib/core/providers/device_provider.dart` — ConnectedDevice.networkId
- `lib/features/scanner/scan_device_tile.dart` — Connect 按鈕取代 tap-to-connect
- `lib/main.dart` — data retention on startup

## Key Changes

### Roster ED 選擇（CMD 0x03/0x04）
- Phone 連 GW 後，Roster tab 顯示同 network ED + Connect/Disconnect 按鈕
- Connect 按鈕發送 CMD 0x03（MAC little-endian），Disconnect 發送 CMD 0x04（ed_index）
- ED 連線狀態用 ED_LIST characteristic address 比對（非 scan 順序）
- EVT INFO 回報（0x20-0x23）觸發 SnackBar + ED_LIST refresh

### 3 個 Critical Bug 修復
- **MAC byte order**：BLE address 是 little-endian，原本直接寫 big-endian 會讓 GW 找不到 ED
- **EVT filter 反了**：`!evt.isAlarm` 過濾掉了 INFO（CMD 回報），改為 `evt.isAlarm` 跳過 ALARM
- **Disconnect slot fallback**：原本 `gwStatus?.edIndex ?? 0` 會斷錯 ED，改用 `edListEntry?.edIndex`

### Pass/Fail 門檻 + Tooltip
- HealthThreshold：RSSI>-65/PDR>95%/Lat<20ms/Jit<5ms，APP 端判定
- Dashboard metrics 顯示綠/橘/紅顏色
- ⓘ info button 加到每個 metric，bottom sheet 說明門檻

## Immediate

1. 等韌體 PR #61 merge 後，實機驗證 Roster Connect/Disconnect（CMD 0x03/0x04 真實 GW↔ED 連線）
2. 從 WSL2 同步最新韌體，燒錄到 GW 裝置

## Backlog

- Admin tab — GW_CFG editor + PIN management（TODO stub）
- L3 工程診斷頁（debug_page.dart）
- Alert 聚合系統（dedup/group/rate-limit）
- Provisioning screen ROLE write 實機測試
- JetBrains Mono .ttf 字體 bundle（目前用 platform monospace）
- In-memory DB → persistent storage（path_provider）

### Key Insights

- **BLE address 在 wire 上是 little-endian**：display format AA:BB:CC:DD:EE:FF 寫到 BLE payload 時必須反轉為 [FF,EE,DD,CC,BB,AA]，ED_LIST 讀取時也要反轉回來才能和 ScannedDevice.id 比對
- **EVT type 0xE2 是 INFO 不是 ALARM**：`isAlarm` 檢查的是 type==0xE1，CMD 回報用 type==0xE2(INFO)，filter 邏輯要跳過 ALARM 處理 INFO
- **實機截圖驗證 ≠ 資料層正確**：UI render 正確（7/7 PASS）不代表底層 CMD payload/byte order/EVT parsing 正確，需要真機 GW↔ED 連線測試
- **ChangeNotifierProvider 會自動 dispose**：不需要在 `ref.onDispose` 再呼叫 `session.dispose()`，否則 double-dispose 導致「used after disposed」

## Environment Notes

- Branch: `feat/gw-roster-ed-selection` on ble_qos_app
- Tests: 182 passing
- Device: Pixel 7a (3A271JEHN05259)
- 韌體 PR #61 待 merge（CMD 0x03/0x04 + EVT INFO）
- app-verify skill 建立在 `~/.claude/skills/app-verify/`
