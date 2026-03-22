# 3. BLE Lifecycle ✅

## 決策

Visible scan + task-scoped connection + explicit background restore。

```
Scanner 頁面（前景）→ filtered scan（只顯示 QoS 裝置）
  │ 選擇裝置 → stopScan
  ▼
Device Session（前景）→ 單台 active 連線 + GATT 讀寫
  │ 離開頁面 / App 背景化
  ▼
背景 → 斷線（不做背景持久連線）
  │ 回到前景
  ▼
恢復 → 重新檢查 BLE 狀態 + 重建 session（不假設連線還在）
```

## Scan 規則

| 規則 | 說明 |
|------|------|
| Scanner 可見才掃 | `Scanner` 頁面在前景 → `startScan(withServices: [QOS_SERVICE_UUID])` |
| 選到即停 | 使用者點選裝置 → `stopScan()` → `push('/device/:id')` |
| 離頁即停 | 離開 Scanner（push 或 pop）→ `stopScan()` |
| 不做 duty cycle | 不做 2s scan / 3s pause 的自管週期（OS 會自己管功耗） |
| Scan TTL | scan result 超過 **30 秒**未更新 → 標為 stale → 超過 **120 秒** → 從列表移除 |

## Connection 規則

| 規則 | 說明 |
|------|------|
| 同時只連一台 | 進入 Device Screen 時連線，離開時斷線 |
| 連線流程 | `connect()` → `discoverServices()` → `PEER_ROLE handshake` → `capability read` → session ready |
| Timeout | connect: 10s / discover: 5s / handshake: 3s / capability read: 3s |
| 失敗處理 | 任一步 timeout → 斷線 + 顯示 error screen + retry 按鈕 |
| 斷線偵測 | `onDisconnected` stream → 自動顯示 reconnect prompt |

## 背景/恢復規則

| 規則 | 說明 |
|------|------|
| 背景不持久連線 | App 進背景 → 主動 `disconnect()`（enterprise field app，不需 24/7 監控） |
| 回前景 = 重新檢查 | 回到 Device Screen → 檢查連線狀態 → 若已斷線 → 自動嘗試重連一次 |
| 不用 OS 背景 BLE | 不做 iOS state restoration / Android foreground service（MVP 不需要） |
| 未來擴展 | 若需要背景告警，再加 OS 原生機制（另開 foundation doc） |

## 重連狀態機

```
CONNECTED
  │ unexpected disconnect
  ▼
RECONNECTING (attempt 1, delay 1s)
  │ fail
  ▼
RECONNECTING (attempt 2, delay 2s)
  │ fail
  ▼
RECONNECTING (attempt 3, delay 4s)
  │ fail
  ▼
DISCONNECTED (show error + manual retry button)
```

- 最多 3 次自動重連，exponential backoff (1s, 2s, 4s)
- 3 次失敗 → 停止自動重連，顯示手動 retry 按鈕
- 使用者主動離開 Device Screen → 不重連

## 大廠做法

- **Apple**：scan only when you need to → 找到就 stopScan → 背景靠 state restoration
- **Android**：不鼓勵 periodic scans → 背景用 PendingIntent scan 或 companion APIs
- **Google BLE Best Practices**：「Connect when you need, disconnect when you don't」

## 影響範圍

- `ble_scanner.dart` — scan lifecycle + TTL eviction
- `ble_connector.dart` — connect/disconnect lifecycle + reconnect
- `ble_reconnect.dart` — exponential backoff state machine
- `scanner_screen.dart` — scan start/stop on visibility
- `device_screen.dart` — connect on enter, disconnect on leave
