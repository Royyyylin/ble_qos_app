# Spec 修訂清單

> 本文件是 spec 修訂的追蹤清單，對照到具體的檔案與行號。
> 所有修訂必須保持三份文件一致，不能出現同一概念在不同文件有不同定義。
> 日期：2026-03-22

---

## 要改的 3 份文件

| 簡稱 | 路徑 | 位置 |
|------|------|------|
| **spec** | `docs/superpowers/specs/2026-03-19-ble-qos-mobile-app-design.md` | App repo |
| **role-pages** | `docs/current/app_role_pages.md` | 韌體 repo |
| **ble_api** | `ble_api.yaml` | 韌體 repo |

---

## 已知的直接衝突（必須同步修）

| # | 衝突 | 文件 A | 文件 B | 決策 |
|---|------|--------|--------|------|
| C1 | CAP 格式 | spec:352 定成 CBOR capability list | ble_api:537 + gatt_services:36 是 `uint8_t` 1-byte bitmask | ✅ **Additive migration：保留 CAP v1 bitmask，新增 CAPS_V2 CBOR** |
| C2 | GW_CFG 權限 | spec:180 給 Role-1 可寫 | role-pages:39 給 installer 唯讀 | ✅ **Role-1 唯讀，Role-2 可寫**（對齊 ble_api:248 engineer_unlock） |
| C3 | Engineer 逾時 | spec:162 定 5 分鐘 | role-pages:30 定 60 秒 | ✅ **5 分鐘**（對齊 ble_api:304 + firmware src） |
| C4 | BLE plugin | spec 已定 `flutter_blue_plus` | role-pages:192 推薦 `flutter_reactive_ble` | **統一為 flutter_blue_plus** |

---

## P0：先收斂合約

### CAP 格式定案 ✅

- **決策**：Additive migration — 保留 CAP v1 bitmask，新增 CAPS_V2 CBOR characteristic
- **理由**：
  1. 符合 spec:722 的 additive-only 原則（不改既有 UUID 語意）
  2. CAP (6f8a9c19) 已在韌體合約成形（ble_api:537），直接改語意會斷掉文件/工具/測試/舊韌體
  3. App 架構需要 CBOR 表達 capability id + version + unknown graceful ignore（spec:341）
  4. 大廠做法一致：SmartThings（capability + version 並存）、Cisco Meraki（breaking change 出新 version）、Azure DTDL（v2/v3 混用遷移）
- **語意定義**：
  - CAP v1 (6f8a9c19)：backward-compatible discovery surface / bootstrap fallback
  - CAPS_V2（新 UUID 待定）：正式 capability contract（CBOR: capability id + version）
- **App 連線讀取順序**：
  1. 讀 FW_VERSION / DEVICE_INFO
  2. 嘗試讀 CAPS_V2
  3. 成功 → versioned capability negotiation
  4. CAPS_V2 不存在 → fallback 到 CAP v1 bitmask
- **修改點**：
  - [x] spec:352 改成描述 CAPS_V2 CBOR，CAP v1 降為 fallback
  - [ ] ble_api.yaml 新增 CAPS_V2 characteristic 定義（UUID 待定）
  - [ ] gatt_services.md 新增 CAPS_V2 說明，CAP v1 標為 legacy fallback
  - [x] 在 spec 補一句：`ble_api.yaml 是 App parser / fixture / validator 的 source of truth`
  - [ ] 韌體 backlog：實作 CAPS_V2 characteristic（CBOR encode capability list）

---

## P1：核心架構修訂

### 掃描與連線 lifecycle

- **改 spec:205**（掃描策略）
  - [x] 刪除「前景 2s / pause 3s」自管週期掃描
  - [x] 改成：Scanner 頁可見 → filtered scan；點擊裝置 → 停掃；離頁/背景 → 停掃
  - [x] 背景需求若存在，改用平台原生背景機制

- **改 spec:230**（連線流程）
  - [x] 補 timeout：connect / discover services / PEER_ROLE handshake / capability read
  - [x] 補錯誤分類：permission_denied / bluetooth_off / busy / timeout / out_of_range / gatt_failure / unexpected_disconnect

### 裝置 identity / 路由

- **改 spec:500**（devices 表 / device identity）
  - [x] `id` 從「BLE MAC or UUID」改成 `device_id: app-side stable ID`
  - [x] 新增 `transport_id: platform BLE identifier`（連線用）
  - [x] 新增 `advertised_address: optional metadata only`
  - [x] 統一用 `device_identity` 一詞，不混 `mac_address`
  - [x] GoRouter `/device/:id` 改成 stable app/device ID

### 狀態管理

- **改 spec:130**（state management 章節）
  - [x] 明寫分層：BLE plugin wrapper（只負責 I/O）→ repository/session controller（狀態源）→ Riverpod providers（只暴露 state）
  - [ ] 補 3 條規則：
    - scan results 有 TTL / stale eviction
    - roster 先合併 scan + GW state，再給 UI
    - live telemetry 跟 session 生命週期走，斷線即 stale/clear

### Auth / Session

- **改 spec:159**（auth 章節）
  - [x] 補明確 policy：Role-1 / Role-2 都是 session-based elevation
  - [x] app kill / cold start 預設回 Role-0
  - [x] local PIN 僅 convenience，不是安全邊界
  - [x] local secret 用 secure storage（iOS Keychain / Android EncryptedSharedPreferences）

- **改 role-pages:26**（權限模型）
  - [x] 對齊 spec 的 session-based 定義

- **解決衝突 C2（GW_CFG 權限）**：
  - [x] spec:181 改成 GW_CFG: Role-1 read-only, Role-2 write（對齊 ble_api:248 engineer_unlock prerequisite）
  - [x] role-pages:39 已正確（installer 唯讀），不用改
  - [ ] backlog：若 Role-1 有現場調整需求，另開 maintenance-safe config surface（子集 characteristic 或白名單欄位），不放開整個 GW_CFG

- **解決衝突 C3（Engineer 逾時）**：
  - [x] role-pages:30 的 60 秒改成 5 分鐘（對齊 ble_api:304 + firmware QOS_ENG_UNLOCK_TIMEOUT_MS）
  - [x] spec:162 已是 5 分鐘，不用改
  - [ ] UX guardrail：剩餘 60 秒顯示倒數警示 + Lock now 按鈕 + 危險操作二次確認

### Capability-driven UI

- **改 spec:374**（capability UI 章節）
  - [x] 補 presentation 規則：capability 決定功能 → role 決定可否操作 → UI tab 由三者推導
  - [x] 禁止 `showControlTab` / `showAdminTab` route-driven 顯示邏輯

### GATT 命令模型

- **改 gatt_services:84**（CMD 說明）
  - [ ] 補 App command contract：每次 write 產生 local transaction id → 等 EVT 有 timeout → timeout 標記失敗 → transient error 有限 retry
  - [ ] CMD_V2 預留 transaction-based interface

### UI/UX 狀態

- **改 spec:249**（Dashboard 章節）
- **改 role-pages:74**（頁面描述）
  - [x] 每個資料卡 4 種狀態：loading / live / stale / unsupported
  - [x] HA tab：capability absent → hidden；capability present but condition unmet → explanatory empty state
  - [x] Connect / Disconnect / Apply / Role write 統一回饋：loading → success / failure with reason

### 導航

- **改 role-pages:171**（畫面狀態機）
  - [x] 補 deep link 進 Device 的行為
  - [x] 補 no-back-stack fallback to Scanner root
  - [x] 補 Provisioning entry from unprovisioned device tile

---

## P2：次要修訂

### 資料層與 retention

- **改 spec:564**（data layer 章節）
  - [x] telemetry 持久化採降採樣，不是 raw notify 全存
  - [x] retention 閾值可配置
  - [x] 補 audit export 能力
  - [x] DB persistent 為正式方向，in-memory 只限 prototype/test

### 測試策略

- **改 spec:112 或新增 testing 章節**
  - [x] 3 層：unit（parser/reducers/auth/timeout/capability）→ widget（scanner/device/error/auth/provisioning）→ integration/HIL（真 BLE）
  - [x] flutter_blue_plus 經 adapter 抽象後以 fake 測，不直接 mock plugin

### 發版與相容矩陣

- **spec:694 後新增章節**
  - [x] FW_VERSION + CAP/version 啟動時檢查
  - [x] 不相容功能顯示 `requires app update`
  - [x] unknown capability graceful ignore
  - [ ] Android Play Data safety / privacy policy
  - [ ] iOS App Store review notes / demo path / crash diagnostics

---

## 依賴順序

```
P0 (CAP 定案) ──→ P1 (capability UI + 相容矩陣)
                     ↑
P1 (identity) ───────┘
P1 (lifecycle / auth / error / state / cmd / UI / nav) ── 可平行
P2 (data / test / release) ── 待 P1 穩定後
```

## 解決衝突的原則

- 兩份文件衝突時，先確認哪邊反映「想要的目標」，另一邊改過來
- 改完後在被修改的文件加 `aligned with: <另一份文件>` 註記
- 三份文件改完後，跑一次 cross-reference check 確認無遺漏
