# Alias / Rename、QoS 呈現、Role / Permission 規則

[← 回 app-scope.md](../app-scope.md)

---

## Alias / Rename Semantics

### 1. Alias 不是 canonical identity

Rename 不得改 `ed_id` / `gw_id`。Alias 只是 display label。

### 2. Display Precedence（定案）

**有 pending op：**
```
local_pending_alias > central_alias > cached_alias > DEVICE_ALIAS (GATT) > adv_name
```

**無 pending op：**
```
central_alias > cached_alias > DEVICE_ALIAS (GATT) > adv_name
```

`DEVICE_ALIAS`（GATT `6f8a9c22`）和 `adv_name` 是 fallback/debug only。

### 3. UI 必須能區分三者

- canonical id（`gw:{mac}` / `ed:{mac}`）
- firmware reported name（BLE adv name）
- user alias（Central-synced or local pending）

### 4. Rename Flow

```
User input → local pending op → optimistic UI update
  → Central 可達 → push → 200: clear pending, update cache
  → Central 不可達 → keep pending, retry on next sync
  → 409 conflict → prompt user (accept Central / overwrite)
```

### 5. Alias Sync 責任

- 本地暫存（PendingAliasOps）
- 成功/失敗回饋（SnackBar）
- 衝突 / stale data 的 UI 顯示（pending / sync failed / conflict badge）

---

## QoS / Health / Failover 呈現

### QoS Metrics

- 7 項 per-ED：RSSI, PDR, Latency, Jitter, PHY, TX Power, Throughput
- 數值 + 單位並排（`-52 dBm`、`99.5 %`、`12 ms`）
- 色彩分級：綠=good、橘=warning、紅=bad
- `--` = 無資料（ED registered 但未 online）
- `N/A` = 非活躍模式（Throughput in non-TP mode）
- 韌體回 0 時保留 last valid

### Health 狀態

- Online / Registered / Empty / Orphaned 的畫面語意
- 區分 device-side（firmware）、gateway-side（GW↔ED link）、central-sync-side 來源

### Failover 呈現

- 顯示 from/to gateway、reason、最近切換時間
- 顯示 切換中 / 穩定中 / 已恢復 等狀態
- **App 可視覺化 failover，不得自行決定最終 authoritative failover 結果**

---

## Role / Permission 顯示原則

### UI Gating 規則

- UI gating 只是使用者體驗與防呆，不是最終安全邊界
- 所有破壞性操作必須有 confirm dialog + explicit feedback
- 權限不足時顯示明確原因（SnackBar），不默默隱藏
- Level 1 的 rename 入口完全隱藏（Schneider 工業模式）

### 角色矩陣

| 角色 | 等級 | 認證方式 | 能力範圍 |
|------|------|---------|---------|
| normal | L1 | 無 | 只讀所有頁面 |
| maintenance | L2 | 6-digit PIN（app-side） | CTRL, GW_CFG, rename, cmdReboot, ROSTER ops |
| engineer | L3 | 8-digit PIN（firmware ENG_UNLOCK） | MODE, ROLE, PIN management, all L2 ops |

### 重要原則

- **local role ≠ Central authoritative permission**
- 本地 PIN 權限與 Central token 權限不得混為一談
- Central auth/RBAC 就緒後，App 的 local role 降級為 UI hint
