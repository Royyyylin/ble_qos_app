# 4. Command Timeout + Error Taxonomy ✅

## Timeout

| 步驟 | timeout |
|------|---------|
| BLE connect | 10s |
| Service discovery | 5s |
| PEER_ROLE handshake | 3s |
| Capability read | 3s |
| CMD write + EVT response | 5s |

## Error 分類

| 類別 | 可重試 | 處理 |
|------|--------|------|
| `permission_denied` | 否 | 引導用戶開權限 |
| `bluetooth_off` | 否 | 引導用戶開藍牙 |
| `device_busy` | 是 | backoff retry |
| `timeout` | 是 | 有限 retry（3-5 次） |
| `out_of_range` | 是 | 提示靠近裝置 |
| `gatt_failure` | 是 | 有限 retry |
| `unexpected_disconnect` | 是 | exponential backoff 3-5 次後停，轉手動 Retry |
