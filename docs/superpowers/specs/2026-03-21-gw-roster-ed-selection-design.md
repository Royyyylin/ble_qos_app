# GW Roster ED Selection

**Date**: 2026-03-21

## Problem

Scanner 目前 tap 整個 tile 就自動連線。用戶需要：
1. 明確的「連線」按鈕（不是 tap tile 自動連線）
2. 連上 GW 後，Roster tab 顯示同 network 的 ED 列表
3. ED 分為「已連線 GW」與「未連線」兩類
4. 永遠只能連一台裝置（舊連線自動斷開）

## Design

### Scanner 改動
- `ScanDeviceTile`: 加 trailing「連線」按鈕，移除 `onTap` 整 tile 觸發
- 連線時舊裝置自動斷開（已實作）

### 全域 Scan Provider
- 新 `scanResultsProvider`: `StateNotifierProvider<ScanResultsNotifier, List<ScannedDevice>>`
- Scanner 掃描結果同步到此 provider
- Roster tab 從此 provider 讀同 network ED

### ED Roster Provider
- 新 `edRosterProvider`: 組合 scan results + GW indexed STATUS notify
- 每收到 indexed STATUS（4-byte, ed_index N），標記 ED N 為「connected to GW」
- 最終輸出：`List<EdRosterEntry>` = {scannedDevice, gwStatus?, isConnectedToGw}

### ED Roster Tab
- 新 `ed_roster_tab.dart` 取代 placeholder
- 顯示 ED 列表：名稱、RSSI、zone badge、GW 連線狀態
- 已連線 ED 顯示從 indexed STATUS 解析的即時數據

### Data Flow
```
BleScanner → scanResultsProvider (global)
                ↓
GW STATUS indexed notify → edRosterProvider
                ↓
EdRosterTab ← edRosterProvider.edList
```

## Files

| File | Action |
|------|--------|
| `lib/core/providers/scan_provider.dart` | NEW |
| `lib/core/providers/ed_roster_provider.dart` | NEW |
| `lib/features/device/roster/ed_roster_tab.dart` | NEW |
| `lib/features/scanner/scan_device_tile.dart` | EDIT — add Connect button |
| `lib/features/scanner/scanner_screen.dart` | EDIT — use scanResultsProvider |
| `lib/features/device/device_screen.dart` | EDIT — wire EdRosterTab |
