# Known Issues — 待修清單

> 2026-03-24 實機驗證後發現的問題。
> 修完後在對應項目標 ✅ + commit hash。

---

## 1. Dashboard STATUS 不即時更新

**現象**：連接 GW 後 Dashboard 只顯示 initial read 的值，之後不再變動。
**根因**：韌體 STATUS notify 只送 4-byte indexed format（zone/profile/phy/tx），不含 rssi/pdr/lat/jit。13-byte full STATUS 只有 GATT read 才拿得到。
**修法**：statusStreamProvider 改成 polling — 每 2 秒 GATT read 13-byte STATUS。4-byte notify 仍保留用於 roster edStatusMap 更新。

## 2. Fleet Overview RSSI 更新頻率不足

**現象**：Scanner 頁面的裝置 RSSI 更新慢。
**修法**：scan result 事件觸發時立即更新 UI（目前已是 stream），但 EMA smoothing 可能延遲感知。確認 `_onScanResults` 每次 scan event 都 emit 到 stream。Flutter Blue Plus `continuousUpdates: true` 應已保證即時。若不足，檢查 scan interval。

## 3. Fleet Overview RSSI 連線後回來不更新

**現象**：從 Device Screen 返回 Scanner，裝置列表的 RSSI 凍結。
**根因**：連線時 `stopScan()` 停掉掃描。返回 Scanner 後沒有重新 `startScan()`。
**修法**：Scanner Screen 用 visibility/lifecycle 觸發 — 進入前景且在 Scanner 頁 → 自動 `startScan()`。離開 → `stopScan()`。

## 4. GW Roster 的 Discovered ED 連線後不消失

**現象**：在 Roster tab 中，Discovered EDs 區塊裡的 ED 即使已經在 Firmware Roster 中（Online），仍然重複顯示在 Discovered 區塊。
**修法**：edRosterProvider 過濾掉已在 firmware roster 中的 ED（MAC match）。只顯示「不在 roster 中」的 discovered ED。

## 5. HA 沒有數值

**現象**：HA tab 永遠顯示 "Waiting for heartbeat..."。
**根因**：haHeartbeatStreamProvider 訂閱 HA_HB notify，但可能：
  - HA_HB characteristic 不支援 READ（只有 write+notify）
  - 單台 GW 沒有 HA pair，不會產生 heartbeat
  - 或 subscribe 失敗（需查 logcat）
**修法**：先查 logcat 確認 subscribe 是否成功。若是「無 HA pair」則顯示明確訊息（非 waiting）。

## 6. Throughput 沒有數值

**現象**：Dashboard 的 Throughput card 永遠顯示 "--"。
**根因**：metricsStreamProvider 讀 METRICS_V2 (0x2A23) 拿到 20 bytes 但 tp_Bps=0。韌體在非 TP test mode 下不填充 throughput 欄位。
**修法**：
  - 若 tp_Bps=0 是預期行為（非 TP test mode），改顯示 "N/A" 或 "Idle" 而非 "--"
  - 或在 Dashboard 只有 TP test mode 啟用時才顯示 Throughput card
