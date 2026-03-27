# BLE App 開發教訓

### UUID 必須逐字對照 ble_api.yaml（2026-03-22）
- PEER_ROLE 6f8a9c14 vs 6f8a9c16，差兩個數字 handshake 就失敗
- 每次新增/修改 UUID 後跑 `grep` 比對 ble_api.yaml

### Wire format 逐 offset 對照，不靠記憶寫（2026-03-24）
- QosCtrl interval 放錯 offset，所有後續欄位串位
- 每個 struct 的 fromBytes/toBytes 都要有 ble_api.yaml offset 註解

### STATUS notify 只有 4-byte indexed，polling 才拿到完整值（2026-03-24）
- 韌體 STATUS notify = zone/profile/phy/tx（4B），沒有 rssi/pdr/lat/jit
- 必須 GATT read polling（2s）取 13-byte full STATUS
- 韌體間歇回 0 → App 保留 last valid value

### autoDispose provider + 有狀態 service = dispose 陷阱（2026-03-23）
- CmdV2Service 在 tab 切換被 dispose → pending Future 拿到 error
- 有狀態的 service dispose 時 return null，不 throw

### 除錯順序：logcat → hierarchy → test → 截圖（2026-03-25）
- 截圖 1200-2000 tokens，logcat 50-200 tokens
- `maestro hierarchy | grep bounds` 一次找到座標
- 截圖只在確認 UI 外觀時才用

### 先讀架構再動手（2026-03-24）
- 不讀 APP_ARCHITECTURE.md 就寫 code = 返工
- 開始任務前必讀：CURRENT.md → 架構 → ble_api.yaml

### 韌體 vs App 問題判斷（2026-03-23）
- `Characteristic not found` = 韌體 PR 沒 merge
- `GATT_WRITE_NOT_PERMITTED` = 韌體 property 沒設
- `全 0 values` = 韌體沒填充，不是 App 解析錯
- 先查 logcat 再決定是誰的問題

### 一次修一個問題（2026-03-22）
- 改完立刻 commit + 驗證，再下一個
- 不要一次改很多再測
