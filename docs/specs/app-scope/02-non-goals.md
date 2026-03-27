# App 不負責範圍 + 反模式

[← 回 app-scope.md](../app-scope.md)

---

## 不負責範圍

### 1. 不得定義跨系統 canonical identity

`gw:{gw_mac}` / `ed:{ed_mac}` / `central_ref` 格式由 Central 定義。
App 只能**消費**這些 identity，不得自行發明替代格式。

### 2. 不得維護 global assignment truth

App 可**顯示** ED 的 active GW、candidate gateways、failover state、orphaned 狀態。
App **不是** authoritative ownership source，不負責 lease truth、conflict resolution、cluster-wide failover decision。

### 3. 不得承擔 telemetry authoritative ingest

App 可讀取、顯示、快取 telemetry。
不負責 canonical ingest、dedup、permanent storage、replay correctness。

### 4. 不得承擔 Central auth policy

App 可執行登入、保存 token、處理 refresh、顯示權限不足。
不定義 RBAC policy、backend authorization、audit authority。

### 5. 不得承擔 firmware runtime truth

App 可顯示 firmware 回報的值。
不得把本地 UI state 當作裝置真實狀態來源。

---

## 反模式（明確禁止）

1. **不得把 alias 當唯一鍵** — alias 是 display label，不是 identity
2. **不得把顯示名稱覆蓋 canonical identity** — rename 只改 alias metadata
3. **不得把 `ed:{gw_mac}/{ed_mac}` 當 ED 永久身分** — 已廢止
4. **不得讓本地快取覆蓋 Central authoritative assignment** — local cache 是 snapshot
5. **不得讓 UI state 假裝成 runtime truth** — App 顯示的是 firmware 回報的值
6. **不得把 firmware name、alias、canonical id 混成同一欄** — 三者必須可區分
7. **不得在 App repo 私自擴充 canonical enum 並與 Central/Firmware 命名衝突**
8. **不得把 BLE name 當唯一鍵** — `fixed_id_24` 只有 24-bit，有碰撞風險
9. **不得把 `node_id` 當跨系統永久 ID** — `uint8_t`，不同網路可能重複
10. **不得同時用 MAC、UUID、`central_ref` 都當主鍵** — 每個系統只有一個 PK
