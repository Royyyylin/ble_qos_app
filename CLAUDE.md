# BLE QoS App — AI Entry Point

所有回覆使用繁體中文（code 和 commit message 用英文）

## 新對話 Onboarding（必讀）

```
1. 讀 docs/architecture/APP_ARCHITECTURE.md  ← 架構決策 SSOT（6 項基石 + 追蹤清單）
2. 讀 .claude/CURRENT.md                     ← 當前進度與待辦
3. 按需讀韌體 repo 的 ble_api.yaml           ← GATT 合約唯一來源
```

## 專案定位

- **Enterprise field app** — 現場工程 / 安裝 / 維運，非 consumer app
- **Flutter 跨平台** — Android 先行，iOS 規劃中
- **韌體 repo 是合約來源** — App 不自行定義 wire format

## Architecture Invariants

### 合約紅線
- **GATT wire format 只從 `ble_api.yaml` 衍生** — App 不得自行定義 byte offset
- **裝置 identity 用 stable ID** — 不用 MAC address 作為 domain identity
- **Capability 決定功能** — `showControlTab` 等不靠 route 參數硬傳

### BLE 紅線
- **Scanner 前景掃描，離頁即停** — 不做全局常駐掃描
- **同一時間只連一台裝置**
- **每個 BLE 操作步驟都有 timeout**

### Auth 紅線
- **Session-based 權限** — App kill 後降回巡視人員
- **PIN 進 secure storage** — 不存明文

### 開發紅線
- 不 hardcode API keys
- Conventional commits
- Push 到 feature branch，CI-green 後 auto-merge

## 未定案事項（阻擋 production code）

見 `docs/architecture/APP_ARCHITECTURE.md` 追蹤清單。
項目 1（CAP 格式）和項目 2（Stable ID）未定案前，不應開始對應模組的 production 重構。

## 韌體 Repo 位置

```
~/ble_qos_demo/ble_qos_demo_V1.2m/
├── ble_api.yaml              ← GATT 合約
├── docs/current/             ← 韌體端 spec
└── src/qos_service.h         ← 韌體實作
```
