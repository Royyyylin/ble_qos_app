# Known Issues — 待修清單

> 2026-03-24 實機驗證後發現的問題。

---

## 1. Dashboard STATUS 不即時更新 ✅

**修復**：statusStreamProvider 改成 polling 2s + last valid value 保留。

## 2. Fleet Overview RSSI 更新頻率不足 ✅

**修復**：scan continuousUpdates 已保證即時。

## 3. Fleet Overview RSSI 連線後回來不更新 ✅

**修復**：RouteAware didPopNext 重啟 scan。

## 4. GW Roster 的 Discovered ED 連線後不消失 ✅

**修復**：edRosterProvider MAC match 過濾。

## 5. HA 沒有數值 ✅

**修復**：CAPS_V2 ha_state=0 → "Standalone Mode"。

## 6. Throughput 沒有數值 ✅

**修復**：tpBps=0 顯示 "N/A"。
