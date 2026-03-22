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
| C1 | CAP 格式 | spec:352 定成 CBOR capability list | ble_api:537 + gatt_services:36 是 `uint8_t` 1-byte bitmask | **待定案**（見 P0） |
| C2 | GW_CFG 權限 | spec:180 給 Role-1 可寫 | role-pages:39 給 installer 唯讀 | **二選一** |
| C3 | Engineer 逾時 | spec:162 定 5 分鐘 | role-pages:30 定 60 秒 | **二選一** |
| C4 | BLE plugin | spec 已定 `flutter_blue_plus` | role-pages:192 推薦 `flutter_reactive_ble` | **統一為 flutter_blue_plus** |

---

## P0：先收斂合約

### CAP 格式定案

- **現狀**：spec 想 CBOR capability list（spec:352），韌體合約是 1-byte bitmask（ble_api:537、gatt_services:36）
- **兩個選項**：
  1. 短期保守：維持 bitmask CAP v1，另開新 characteristic 做 CBOR capabilities
  2. 中期正規：把 CAP 升成版本化 CBOR，同步改 firmware / docs / yaml
- **修改點**：
  - [ ] 定案後更新 spec:352
  - [ ] 定案後更新 ble_api:537
  - [ ] 定案後更新 gatt_services:36
  - [ ] 在 spec 補一句：`ble_api.yaml 是 App parser / fixture / validator 的 source of truth`

---

## P1：核心架構修訂

### 掃描與連線 lifecycle

- **改 spec:205**（掃描策略）
  - [ ] 刪除「前景 2s / pause 3s」自管週期掃描
  - [ ] 改成：Scanner 頁可見 → filtered scan；點擊裝置 → 停掃；離頁/背景 → 停掃
  - [ ] 背景需求若存在，改用平台原生背景機制

- **改 spec:230**（連線流程）
  - [ ] 補 timeout：connect / discover services / PEER_ROLE handshake / capability read
  - [ ] 補錯誤分類：permission_denied / bluetooth_off / busy / timeout / out_of_range / gatt_failure / unexpected_disconnect

### 裝置 identity / 路由

- **改 spec:500**（devices 表 / device identity）
  - [ ] `id` 從「BLE MAC or UUID」改成 `device_id: app-side stable ID`
  - [ ] 新增 `transport_id: platform BLE identifier`（連線用）
  - [ ] 新增 `advertised_address: optional metadata only`
  - [ ] 統一用 `device_identity` 一詞，不混 `mac_address`
  - [ ] GoRouter `/device/:id` 改成 stable app/device ID

### 狀態管理

- **改 spec:130**（state management 章節）
  - [ ] 明寫分層：BLE plugin wrapper（只負責 I/O）→ repository/session controller（狀態源）→ Riverpod providers（只暴露 state）
  - [ ] 補 3 條規則：
    - scan results 有 TTL / stale eviction
    - roster 先合併 scan + GW state，再給 UI
    - live telemetry 跟 session 生命週期走，斷線即 stale/clear

### Auth / Session

- **改 spec:159**（auth 章節）
  - [ ] 補明確 policy：Role-1 / Role-2 都是 session-based elevation
  - [ ] app kill / cold start 預設回 Role-0
  - [ ] local PIN 僅 convenience，不是安全邊界
  - [ ] local secret 用 secure storage（iOS Keychain / Android EncryptedSharedPreferences）

- **改 role-pages:26**（權限模型）
  - [ ] 對齊 spec 的 session-based 定義

- **解決衝突 C3**：
  - [ ] spec:162 的 5 分鐘 vs role-pages:30 的 60 秒 → 選一個，兩邊同步

### Capability-driven UI

- **改 spec:374**（capability UI 章節）
  - [ ] 補 presentation 規則：capability 決定功能 → role 決定可否操作 → UI tab 由三者推導
  - [ ] 禁止 `showControlTab` / `showAdminTab` route-driven 顯示邏輯

### GATT 命令模型

- **改 gatt_services:84**（CMD 說明）
  - [ ] 補 App command contract：每次 write 產生 local transaction id → 等 EVT 有 timeout → timeout 標記失敗 → transient error 有限 retry
  - [ ] CMD_V2 預留 transaction-based interface

### UI/UX 狀態

- **改 spec:249**（Dashboard 章節）
- **改 role-pages:74**（頁面描述）
  - [ ] 每個資料卡 4 種狀態：loading / live / stale / unsupported
  - [ ] HA tab：capability absent → hidden；capability present but condition unmet → explanatory empty state
  - [ ] Connect / Disconnect / Apply / Role write 統一回饋：loading → success / failure with reason

### 導航

- **改 role-pages:171**（畫面狀態機）
  - [ ] 補 deep link 進 Device 的行為
  - [ ] 補 no-back-stack fallback to Scanner root
  - [ ] 補 Provisioning entry from unprovisioned device tile

---

## P2：次要修訂

### 資料層與 retention

- **改 spec:564**（data layer 章節）
  - [ ] telemetry 持久化採降採樣，不是 raw notify 全存
  - [ ] retention 閾值可配置
  - [ ] 補 audit export 能力
  - [ ] DB persistent 為正式方向，in-memory 只限 prototype/test

### 測試策略

- **改 spec:112 或新增 testing 章節**
  - [ ] 3 層：unit（parser/reducers/auth/timeout/capability）→ widget（scanner/device/error/auth/provisioning）→ integration/HIL（真 BLE）
  - [ ] flutter_blue_plus 經 adapter 抽象後以 fake 測，不直接 mock plugin

### 發版與相容矩陣

- **spec:694 後新增章節**
  - [ ] FW_VERSION + CAP/version 啟動時檢查
  - [ ] 不相容功能顯示 `requires app update`
  - [ ] unknown capability graceful ignore
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
