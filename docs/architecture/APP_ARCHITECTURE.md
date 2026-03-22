# BLE QoS App — Architecture Decision Record

> 本文件是 App 架構的 single source of truth。
> 任何 AI agent 接手此專案，必須先讀本文件再動手。
> 最後更新：2026-03-22

**相關文件**：
- [DECISIONS_60Q.md](DECISIONS_60Q.md) — 60 題逐題決策
- [SPEC_REVISION_CHECKLIST.md](SPEC_REVISION_CHECKLIST.md) — spec 修訂追蹤

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

每項的完整決策、大廠依據、待定細節見 `foundations/` 子資料夾。

| # | 項目 | 狀態 | 文件 |
|---|------|------|------|
| 1 | CAP 格式：Additive migration（bitmask + CBOR） | ✅ | [foundations/01-capability-format.md](foundations/01-capability-format.md) |
| 2 | 裝置 Identity：stable ID hierarchy，MAC 不進主模型 | ⏳ | [foundations/02-device-identity.md](foundations/02-device-identity.md) |
| 3 | BLE Lifecycle：前景掃描 + 任務型連線 + 背景顯式恢復 | ⏳ | [foundations/03-ble-lifecycle.md](foundations/03-ble-lifecycle.md) |
| 4 | Timeout + Error：5 個 timeout + 7 類 error | ✅ | [foundations/04-timeout-error.md](foundations/04-timeout-error.md) |
| 5 | Auth：session-based / GW_CFG Role-1 唯讀 / 5 分鐘 | ✅ | [foundations/05-auth-session.md](foundations/05-auth-session.md) |
| 6 | 相容矩陣：CAPS_V2 → fallback CAP v1 → graceful degrade | ⏳ | [foundations/06-compat-matrix.md](foundations/06-compat-matrix.md) |

**執行順序**：#2 → #6 → #3（#1/#4/#5 已定案）

---

## 架構分層（目標狀態）

```
lib/
├── main.dart                      # GoRouter + ProviderScope
├── core/
│   ├── ble/                       # BLE transport + BleAdapter 介面
│   ├── gatt/                      # GATT 協議（從 ble_api.yaml 衍生）
│   ├── auth/                      # Session-based 權限
│   ├── capability/                # CAP 解析 + version compatibility + feature gate
│   ├── device/                    # 裝置 identity（stable ID，非 MAC）
│   ├── providers/                 # Riverpod state holders
│   ├── data/                      # Drift DB（persistent，migration additive-only）
│   ├── domain/                    # 業務邏輯
│   ├── error/                     # Error taxonomy + retry policy
│   └── theme/
├── features/                      # 畫面（由 capability + role 動態決定）
├── widgets/                       # 共用 UI 元件
└── data/                          # 靜態資料
```

## 核心原則

**狀態管理**：BleAdapter 介面 → adapter/repository + Riverpod state holder → 依賴鏈單向（scan → session → telemetry → UI）

**UI**：0 值不偽裝正常 → waiting/stale/unsupported 狀態；操作統一 loading → success/failure 回饋；notify 更新節流

**測試**：unit（parser/reducer/auth）→ widget（權限/導航）→ integration/HIL（真 BLE）；flutter_blue_plus 包 adapter 用 fake

---

## 參考來源

- Apple CoreBluetooth Best Practices / Background Processing
- Google Android BLE Permissions (12+) / Architecture Recommendations
- Samsung SmartThings Device Profiles / Capabilities / Presentations
- Cisco Meraki API Versioning / Deprecation / Dashboard Access
- Azure DTDL v2/v3 Model Versioning
