# Canonical Identity 對齊 + 三層分離模型

[← 回 app-scope.md](../app-scope.md)

---

## Canonical Identity（定案 2026-03-27）

### GW

```
gw_id = gw:{gw_mac}
```

### ED

```
ed_id = ed:{ed_mac}
```

ED identity 只包含 ED 自身的 MAC，**不包含 GW MAC**。`central_ref` 跨 failover 不變。

### 明確禁止

App 文件中**不得**再將以下格式定義為 ED 永久身分：

| 舊格式 | 狀態 | 僅可用於 |
|--------|------|---------|
| `ed:{gw_mac}/{ed_mac}` | **已廢止** | route_ref, debug path, display-only relation |
| `ed:{gw_identity}/{provisioning_id}` | **已廢止** — 韌體無此概念 | 完全移除 |

---

## Identity 職責對照表

| 角色 | 身分 | 格式 | 用途 | 禁止 |
|------|------|------|------|------|
| 主裝置身分 | BLE MAC | `AA:BB:CC:DD:EE:FF` | 跨系統唯一真實身分，`central_ref` 基礎 | 不當 DB 主鍵 |
| 系統 DB 主鍵 | UUID | App: `stableId` (UUIDv4)、Central: `central_ref` | 各系統內部 PK、API path | 不暴露給韌體 |
| 通訊/拓撲身分 | HA `node_id` | `uint8_t` | HA heartbeat、mesh routing | 不當跨系統永久 ID |
| 人類可讀名稱 | alias / BLE name | UTF-8 string | 純顯示用 | 不當唯一鍵 |

---

## 三層分離模型

App 必須採用：

| 層 | 內容 | 是否可變 |
|---|---|---|
| **Identity** | `ed_id`, `gw_id`, MAC | 不可變 |
| **Assignment** | `active_gateway_id`, `candidate_gateway_ids`, `assignment_state` | 可變（failover 改這層） |
| **Routing** | `last_failover_reason`, `last_failover_from/to` | 可變（事件紀錄） |

App 必須明文禁止：

- 用目前掛哪台 GW 來重命名 ED 主身分
- 用畫面上的路徑字串取代 canonical identity
- 讓 UI alias 寫回後污染 canonical identity
- 讓本地快取覆蓋 authoritative assignment truth
