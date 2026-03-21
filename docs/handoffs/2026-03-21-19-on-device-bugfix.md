# EOD Handoff — 2026-03-21 19:45

**Date**: 2026-03-21
**Session Type**: bugfix + on-device testing
**Repo(s) Affected**: ble_qos_app

## Summary

實機測試發現並修復 3 個 BLE 資料層 bug + 2 個 UX bug。Dashboard 從全 `--` 到正確顯示韌體即時數據，GW 正確顯示 4 tab（Dashboard/Roster/HA/Control）。

## Modified Files

- `lib/core/gatt/gatt_structs.dart` — QosStatus parser 重寫：對齊韌體 byte layout + 新增 4-byte indexed format parser
- `lib/core/providers/metrics_provider.dart` — 加 initial GATT read fallback（設備不送 notify 時也能顯示數據）；STATUS provider 改為雙格式自動偵測
- `lib/core/providers/device_provider.dart` — ConnectedDevice 加 role 欄位，從 mfgData 讀取
- `lib/features/device/device_screen.dart` — 移除寫死 capabilities，改用 fallbackForRole() 動態決定 tab
- `lib/features/scanner/scanner_screen.dart` — 加 loading overlay、連線前 disconnect 上一台、改 context.push 啟用 back navigation
- `lib/main.dart` — 移除寫死的 capabilities 參數
- `scripts/screenshot.sh` — adb 截圖 + 縮圖 script（給 Claude 用）
- `test/gatt_structs_test.dart` — QosStatus 測試對齊新韌體格式 + indexed format 測試
- `test/features/device/device_screen_test.dart` — 改用 role-based provider override

## Key Changes

### Bug 1: QosStatus parser 與韌體不一致
- **症狀**：Dashboard 全顯示 `--`
- **原因**：App parser 假設 byte 順序 [zone, profile, phy, ...]，但韌體實際是 [rssi, pdr_x100, lat_ms, ...]
- **修復**：重寫 `QosStatus.fromBytes()` 對齊 `qos_service.h` 的 `struct qos_status`

### Bug 2: GW 送 4-byte indexed STATUS，App 期望 13-byte
- **症狀**：GW 連線後 notify 數據全被 size filter 過濾
- **原因**：GW 用 `qos_pack_status_idx()` 送壓縮格式，App 只接受 13 bytes
- **修復**：加 `QosStatus.fromIndexedBytes()` + `parse()` 自動偵測格式

### Bug 3: capabilities 寫死
- **症狀**：GW 只顯示 Dashboard + Control 兩個 tab
- **原因**：`main.dart` 寫死 `capabilities: [qos_monitor]`
- **修復**：`DeviceScreen` 從 `connectedDeviceProvider.role` 讀取，用 `fallbackForRole()` 動態決定

### UX Fix: 連線無反饋 + 無返回按鈕
- 加 "Connecting..." loading overlay
- 連線前 disconnect 上一台裝置
- `context.go()` → `context.push()` 啟用 back navigation

## Immediate

1. 繼續實機測試：HA tab、Control tab 的 GATT write 功能
2. 確認 GW 的 4-byte indexed notify 是否有即時更新 Dashboard（目前只看到 initial read 值）

## Backlog

- Audit log 寫入（table 在但 feature actions 沒呼叫 audit write）
- GW_CFG editor（admin_tab.dart TODO stub）
- PIN management（admin_tab.dart TODO stub）
- Demo tab 內容

### Key Insights

- 韌體的 GATT struct 和 App 的 parser 必須用同一份 header 對齊，不能假設欄位順序
- GW 的 multi-ED indexed notify（4 bytes）是壓縮格式，和 GATT read 的完整 struct（13 bytes）不同，App 要能處理兩種格式
- `context.go()` 替換路由沒有 back stack，需要 `context.push()` 才有返回功能
- adb screencap + sips resize 可以讓 AI 直接截圖驗證 UI

## Environment Notes

- Flutter tests: 141 passing
- Build: `export JAVA_HOME=$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home`
- Device: Pixel 7a, Android 16
- 韌體裝置：1 GW (FGWAF37FD) + 2 ED (FEDDF3AD0, FED498B6E)，全部 Network 0
