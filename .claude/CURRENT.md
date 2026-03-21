# BLE QoS App — Current State

**最後更新：** 2026-03-21

## 進度

- [x] Design Spec 全面實作（15 tasks TDD, PR #1 merged）
- [x] Android 實機部署到 Pixel 7a
- [x] BLE 掃描 + 連線 + PEER_ROLE handshake
- [x] PING keep-alive（20s 間隔）
- [x] QosStatus parser 對齊韌體（13-byte full + 4-byte indexed）
- [x] Dynamic capabilities（GW: Dashboard/Roster/HA/Control, ED: Dashboard/Control）
- [x] Initial GATT read fallback（設備不送 notify 也能顯示數據）
- [x] Loading overlay + back navigation
- [ ] HA tab 實機驗證
- [ ] Control tab GATT write 實機驗證
- [ ] Audit log 寫入接線
- [ ] GW_CFG editor 實作
- [ ] PIN management 實作

## 下一步（優先順序）

1. 實機測試 HA tab（GW 連線後切到 HA tab 看 heartbeat）
2. 實機測試 Control tab（CTRL write profile 切換）
3. Audit log 寫入接線（feature actions 呼叫 audit repository）
4. Dashboard 數據標籤優化（Zone 顯示 NEAR/MID/FAR 而非數字）

## 已知問題

- GW 的 STATUS indexed notify 只有 zone/profile/phy/txPower/interval，缺 rssi/pdr/latency/jitter — 需韌體送完整 struct 或 App 用 METRICS notify 補
- ED 不主動送 STATUS notify，只靠 initial read — 數據是靜態的
- flutter build apk 需要手動 export JAVA_HOME

## 測試

- 141 unit tests passing
- 實機驗證：Scanner（3 devices）, Dashboard（GW + ED）, 連線/斷線/重連

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17: /opt/homebrew/opt/openjdk@17
- 韌體裝置：1 GW + 2 ED, Network 0
