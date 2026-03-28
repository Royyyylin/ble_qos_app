# App 輸入/輸出契約 + 介面切分

[← 回 app-scope.md](../app-scope.md)

---

## App Must Consume

### 1. Central metadata

- GW / ED canonical identity（`gw:{mac}` / `ed:{mac}`）
- assignment / active gateway
- alias / name / label metadata + revision
- role / permission metadata

### 2. Firmware runtime status（via GATT, profile-aware）

**注意：** Firmware payload 有 P0/P1 兩種 profile。P0 欄位極稀疏，App 不得假設所有 GATT data 都有完整欄位。缺值欄位 nullable，不視為錯誤。

| Characteristic | Size | 方式 | 內容 |
|----------------|------|------|------|
| STATUS (0x2A1D) | 13B | polling 2s | per-ED QoS: RSSI, PDR, latency, jitter, profile, PHY, TX, interval |
| METRICS_V2 (0x2A23) | 20B | notify | extended metrics + throughput + pressure |
| EVT (6f8a9c13) | 6B | notify/indicate | alarms + info events |
| ROSTER_LIST (6f8a9c20) | N×9B | read | slot state snapshot |
| CAPS_V2 (6f8a9c21) | ~30B | read (CBOR) | capability + HA state |
| FW_VERSION (6f8a9c1b) | 6B | read | firmware version |
| DEVICE_INFO (6f8a9c1c) | 8B | read 30s | uptime, reset count, role |

### 3. Auth / policy results

- Central token status（future）
- Local PIN validation result
- Permission denied feedback

---

## App May Emit

### 1. User intent / commands

| Intent | 目標 | 方式 |
|--------|------|------|
| rename alias | Central API (or local pending) | PUT /api/devices/{ref}/metadata |
| ROSTER_ADD / ROSTER_REMOVE | firmware GATT | CMD_V2 opcode 0x05/0x06 |
| CONNECT_ED / DISCONNECT_ED | firmware GATT | CMD_V2 opcode 0x03/0x04 |
| CTRL write | firmware GATT | write 0x2A21 |
| ENG_UNLOCK / ENG_PIN_SET | firmware GATT | write 6f8a9c11/12 |
| CMD Reboot | firmware GATT | CMD_V2 opcode 0x01 |

### 2. UI preferences（local only）

- filter / sort / display options
- default tab

App emit 的是 **intent** 或 **UI-side request**，不是 authoritative global truth。

---

## 介面邊界

### App ↔ Central

| App 負責 | App 不負責 |
|---------|-----------|
| 讀取 metadata / assignment / policy | metadata truth merge algorithm |
| 發送 rename / add / remove intent | global lease authority |
| 呈現 authoritative global state | backend policy definition |
| 處理 auth / token / permission | dedup truth |

### App ↔ Firmware

| App 負責 | App 不負責 |
|---------|-----------|
| 顯示 firmware runtime state | runtime QoS measurement 真實性 |
| 透過 GATT 觸發近端操作 | device sequence/dedup semantics |
| 提供 debug / maintenance 視圖 | firmware failover algorithm |
