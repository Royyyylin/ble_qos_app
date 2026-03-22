# BLE QoS App — Architecture Decision Record

> 本文件是 App 架構的 single source of truth。
> 任何 AI agent 接手此專案，必須先讀本文件再動手。
> 逐題決策細節見 [DECISIONS_60Q.md](DECISIONS_60Q.md)。
> 最後更新：2026-03-22

---

## 定位

- **類型**：Enterprise field app（現場工程 / 安裝 / 維運）
- **主用戶**：工程師、安裝人員、巡視人員（三角色）
- **不是**：consumer app、資料長時間儲存端、正式資料接收端
- **平台**：Flutter 跨平台（Android 先行，iOS 規劃中）

## 合約來源

```
韌體 repo: ble_qos_demo_V1.2m/
├── ble_api.yaml                    ← GATT 合約 SSOT（UUID + wire format + semantics）
├── docs/current/gatt_services.md   ← GATT 特徵值文件（與 ble_api.yaml 對齊）
├── docs/current/app_role_pages.md  ← 角色 × 頁面 × 權限矩陣
└── src/qos_service.h               ← 韌體實作（ble_api.yaml 從此生成）
```

**規則**：App code 不得自行定義 wire format。所有 byte layout、UUID、enum 必須從 `ble_api.yaml` 衍生。

---

## 六項架構基石

以下 6 項是所有功能實作的前提，未定案前不應開始對應模組的 production code。

### 1. Capability 格式統一

**現狀衝突**：
- App spec（`2026-03-19-ble-qos-mobile-app-design.md:352`）定義 CAP 為 CBOR capability list
- 韌體文件（`gatt_services.md:36`）定義 CAP 為 `uint8_t` 1-byte bitmask
- `ble_api.yaml` 需要反映最終決定

**決策**：（待定案）
- [ ] 選定 CAP 格式（CBOR / bitmask / 其他）
- [ ] 更新 `ble_api.yaml` 為唯一來源
- [ ] App 端 `CapabilityRegistry` 從 `ble_api.yaml` 衍生，不硬編碼

**影響範圍**：capability negotiation、tab 顯示、version compatibility、graceful degradation

### 2. 裝置 Identity

**問題**：iOS 不暴露 BLE MAC address，Android 也不應把 MAC 當 domain identity。

**決策**：
- 裝置 identity 使用平台無關的 stable ID（device_identity / provisioning ID / network_id）
- MAC address 只作為 transport metadata（BLE 連線用）
- GoRouter 的 `/device/:id` 和 DB 主鍵都用 stable ID，不用 MAC

**影響範圍**：路由、DB schema、scan result model、所有 device reference

### 3. BLE Lifecycle

**決策**：
```
Scanner 頁面（前景）→ 掃描
  │ 選擇裝置
  ▼
Device Session（前景）→ 單台 active 連線 + PING keepalive
  │ 離開頁面 / App 背景化
  ▼
背景 → 停掃、斷線或顯式 OS 背景機制（不靠全局常駐掃描）
  │ 回到前景
  ▼
恢復 → 明確的 reconnect flow
```

- **不做**：全 App 常駐掃描、2s/3s duty scan 撐全局
- **掃描**：只在 Scanner 前景頁，離頁即停
- **連線**：同一時間只連一台裝置
- **背景**：必要時用 OS 原生背景 BLE 機制，不自己撐

### 4. Command Timeout + Error Taxonomy

**每一步都要 timeout**：
| 步驟 | 建議 timeout |
|------|-------------|
| BLE connect | 10s |
| Service discovery | 5s |
| PEER_ROLE handshake | 3s |
| Capability read | 3s |
| CMD write + EVT response | 5s |

**Error 分類**：
| 類別 | 可重試 | 處理 |
|------|--------|------|
| `permission_denied` | 否 | 引導用戶開權限 |
| `bluetooth_off` | 否 | 引導用戶開藍牙 |
| `device_busy` | 是 | backoff retry |
| `timeout` | 是 | 有限 retry（3-5 次） |
| `out_of_range` | 是 | 提示靠近裝置 |
| `gatt_failure` | 是 | 有限 retry |
| `unexpected_disconnect` | 是 | exponential backoff 3-5 次後停，轉手動 Retry |

### 5. 認證 Session-Based

**決策**：
- 角色提升是 session，不是永久 entitlement
- App 被 kill → 重啟後回到「巡視人員」（Normal）
- 工程師模式有 60 秒逾時自動降權（韌體端 `ENG_UNLOCK`）
- PIN 存 secure storage（iOS Keychain / Android EncryptedSharedPreferences），不存明文
- 本地 PIN 驗證只算便利功能，不算安全邊界

### 6. App/FW 相容矩陣

**流程**：
```
連線後 → 讀 FW_VERSION + DEVICE_INFO + CAP
  → 對照相容矩陣
  → 決定顯示哪些功能
  → 不相容的功能 graceful degrade（灰色 + 提示「需要韌體 vX.Y」）
```

**相容矩陣格式**：
```yaml
compatibility:
  - app_version: ">=1.0"
    fw_version: ">=1.2.0"
    features: [dashboard, roster, control, ha]
  - app_version: ">=1.0"
    fw_version: ">=1.3.0"
    features: [dashboard, roster, control, ha, cmd_v2, admin]
```

**規則**：
- App 不得假設韌體版本，必須動態讀取
- 功能開關由 capability + version 推導，不靠 route 參數硬傳
- `showControlTab` / `showAdminTab` 由 `role + capability + version` 三者共同決定

---

## 架構分層（目標狀態）

```
lib/
├── main.dart                      # GoRouter + ProviderScope
├── core/
│   ├── ble/                       # BLE transport（scanner, connector, reconnect）
│   │   └── ble_adapter.dart       # 介面抽象（可 fake 測試）
│   ├── gatt/                      # GATT 協議（從 ble_api.yaml 衍生）
│   │   ├── gatt_contract.dart     # UUID + struct 定義（generated 或 hand-aligned）
│   │   └── gatt_cmd_service.dart  # CMD 高層 API + timeout
│   ├── auth/                      # Session-based 權限
│   ├── capability/                # CAP 解析 + version compatibility + feature gate
│   ├── device/                    # 裝置 identity（stable ID，非 MAC）
│   ├── providers/                 # Riverpod state holders（非 singleton wrapper）
│   │   ├── scan_provider.dart     # 生命週期：Scanner 前景頁
│   │   ├── session_provider.dart  # 生命週期：active BLE connection
│   │   └── telemetry_provider.dart # 生命週期：跟隨 session，斷線清 stale
│   ├── data/                      # Drift DB（persistent，migration additive-only）
│   ├── domain/                    # 業務邏輯
│   ├── error/                     # Error taxonomy + retry policy
│   └── theme/
├── features/                      # 畫面（由 capability + role 動態決定）
├── widgets/                       # 共用 UI 元件
└── data/                          # 靜態資料
```

### 狀態管理原則

- BLE 層包一層 `BleAdapter` 介面，production 用 `flutter_blue_plus`，測試用 `FakeBleAdapter`
- 不讓 singleton 成為核心狀態來源 → 改成 adapter/repository + Riverpod state holder
- scan / session / telemetry 各自有明確生命週期：
  - `scanResults`：有 TTL / eviction，離開 Scanner 頁即停止更新
  - `session`：跟著 BLE connection 走
  - `telemetry`：跟著 session 走，斷線即標記 stale
- 依賴鏈維持單向：scan → roster → session → telemetry（不反向）

### UI 原則

- 0 值 / null 不偽裝成正常資料 → 顯示 `waiting` / `stale` / `unsupported` / `requires dual-GW`
- Connect / Disconnect / Apply 統一 loading → success / failure 回饋
- notify 更新要節流（throttle），不是每包都重建整頁

### 測試三層

| 層級 | 範圍 | 工具 |
|------|------|------|
| Unit | parser, reducer, RBAC, timeout, error taxonomy | `flutter_test` + fake adapter |
| Widget | 權限流程, 導航, 關鍵 UI 流程 | `flutter_test` + `WidgetTester` |
| Integration | 真 BLE 裝置端到端 | `app-verify` skill + adb |

---

## 追蹤清單

| # | 項目 | 狀態 | 阻擋 |
|---|------|------|------|
| 1 | CAP 格式定案 | ⏳ 待決定 | 2, 6 |
| 2 | 裝置 stable ID 設計 | ⏳ 待設計 | 3 |
| 3 | BLE lifecycle 重構 | ⏳ 待 1, 2 | — |
| 4 | Command timeout + error taxonomy | ⏳ 可先行 | — |
| 5 | Auth session-based 重構 | ⏳ 可先行 | — |
| 6 | App/FW 相容矩陣 | ⏳ 待 1 | — |

**依賴關係**：
```
1 (CAP 格式) ──→ 6 (相容矩陣) ──→ 3 (BLE lifecycle)
                                      ↑
2 (Stable ID) ─────────────────────────┘
4 (Timeout/Error) ── 獨立，可先行
5 (Auth Session) ── 獨立，可先行
```

---

## 參考來源

- Apple CoreBluetooth Best Practices
- Apple Background Processing for BLE
- Google Android BLE Permissions (Android 12+)
- Google Android Architecture Recommendations
- Samsung SmartThings Device Profiles / Capabilities / Presentations
- Cisco Meraki Dashboard Access / Data Availability / Firmware Release Process
