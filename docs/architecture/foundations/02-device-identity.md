# 2. 裝置 Identity ✅

## 決策

韌體目前不提供 serial number 或 device ID characteristic。MAC 是唯一 on-wire identifier。因此：

### Identity Hierarchy

```
device_id (App-generated UUIDv4)    ← DB 主鍵、GoRouter ID、跨 session 穩定
  ├─ transport_id (platform BLE ID) ← 連線用（iOS: CBPeripheral.identifier / Android: MAC）
  └─ mac_address (metadata only)    ← 顯示用、ED_LIST matching、CMD 0x03 payload
```

### 生成規則

1. **首次掃描到新裝置** → App 用 `uuid.v4()` 生成 `device_id`
2. **device_id ↔ transport_id 映射**存在 Drift DB `devices` 表
3. **跨 session 識別**：下次掃描到同一個 `transport_id` → 查 DB 找回 `device_id`
4. **iOS 跨安裝**：`CBPeripheral.identifier` 在同一台 iPhone 上穩定，但換手機會變 → `device_id` 也會重新生成（可接受，因為 field app 通常綁定一台手機）

### 為什麼不用 MAC 當主鍵

- iOS 不暴露 BLE MAC address（只有 CBPeripheral.identifier UUID）
- Android 的 MAC 可能因 BLE random address 而變
- 業界做法（SmartThings、Meraki）都不用 transport address 當 domain identity

### 為什麼不等韌體加 DEVICE_IDENTITY characteristic

- 韌體 PR 週期長，App 不應被 block
- App-generated ID 已足夠（field app 綁定一台手機使用）
- 未來韌體若加 serial number，可作為更穩定的 `provisioning_id` 層

## Migration Path（從 MAC-based 到 stable-ID）

### Phase 1: DB schema migration（additive）

```sql
-- devices 表新增欄位
ALTER TABLE devices ADD COLUMN device_id TEXT;
ALTER TABLE devices ADD COLUMN transport_id TEXT;
-- 遷移既有資料：device_id = UUIDv4()，transport_id = 原 id (MAC)
-- 新主鍵：device_id
```

### Phase 2: App 層改動（9 個 touch point）

| 層 | 改動 | 檔案 |
|----|------|------|
| ScannedDevice | 新增 `deviceId` 欄位，scan 時從 DB 查或新建 | `ble_models.dart` |
| GoRouter | `/device/:id` 改傳 `device_id`（不是 MAC） | `main.dart` |
| DeviceScreen | `deviceId` 參數改為 stable ID | `device_screen.dart` |
| ConnectedDevice | `id` 改為 `device_id` | `device_provider.dart` |
| Scanner dedup | dedup key 改為 `transport_id`（掃描層仍用 platform ID） | `ble_scanner.dart` |
| BleConnector | `connect()` 參數仍用 `transport_id`（BLE stack 需要它） | `ble_connector.dart` |
| ED roster matching | MAC matching 不變（CMD 0x03 需要 MAC） | `ed_roster_provider.dart` |
| CMD 0x03 | payload 仍用 MAC bytes（韌體合約不變） | `gatt_structs.dart` |
| DB | 主鍵改 `device_id`，`transport_id` + `mac_address` 為 indexed columns | `devices.dart` |

### Phase 3: 韌體 backlog（未來）

- 若韌體新增 DEVICE_IDENTITY characteristic（serial / provisioning ID）
- App 讀取後存為 `provisioning_id`，作為比 `transport_id` 更穩定的 mapping key
- `device_id` 不變（App 端生成，已跨 session 穩定）

## 大廠做法

- **Apple**：`CBPeripheral.identifier` 取回已知裝置；BLE random address 會變，不當長期身份
- **Cisco Meraki**：inventory 以 serial / cloud ID / org / network assignment 管理；MAC 可查但非主鍵
- **SmartThings**：device profile / capability id / component id，不用 transport address 當 domain model

## 影響範圍

路由、DB schema、scan result model、device provider、所有 device reference。
CMD 0x03/0x04 的 wire payload **不變**（韌體合約不動）。
