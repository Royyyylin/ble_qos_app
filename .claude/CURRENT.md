# BLE QoS App — Current State

**最後更新：** 2026-03-22

## 架構決策進度

4 個合約衝突已全部定案（C1 CAP 格式 / C2 GW_CFG 權限 / C3 Engineer 逾時 / C4 BLE plugin）。
詳見 `docs/architecture/APP_ARCHITECTURE.md`。

### 剩餘待定（執行順序）
1. **#2 裝置 stable ID** — identity hierarchy 方向已定（device_identity > provisioning_id > transport_id），細節待設計
2. **#6 App/FW 相容矩陣** — CAP 已定案，可開始定 negotiation read order + degradation 規則
3. **#3 BLE lifecycle 重構** — 待 #2 stable ID 定案

### 已定案
- #1 CAP 格式：Additive migration（CAP v1 bitmask fallback + CAPS_V2 CBOR）
- #4 Timeout + Error：5 個 timeout + 7 類 error
- #5 Auth：session-based / GW_CFG Role-1 唯讀 / 5 分鐘 engineer timeout

## Prototype 進度

- [x] Design Spec 全面實作（15 tasks TDD, PR #1 merged）
- [x] Android 實機部署到 Pixel 7a
- [x] BLE 掃描 + 連線 + PEER_ROLE handshake
- [x] GW Roster ED 選擇（CMD 0x03/0x04）+ 8 bug fix
- [x] Pass/Fail 門檻 + Tooltip 系統
- [x] 7/7 實機截圖驗證 PASS
- [x] 搜尋框 auto-focus bug 修復

## 下一步

1. 定案 #2 stable ID 細節
2. 定案 #6 相容矩陣
3. 定案 #3 BLE lifecycle
4. 開始執行 spec 修訂（SPEC_REVISION_CHECKLIST.md 的 checkbox）
5. 實機測試 Roster Connect/Disconnect（韌體 PR #61 已 merge）

## Backlog

- App API for AI Agent（MCP Server / ADB Intent / Headless BLE / WebSocket）
- Admin tab — GW_CFG editor + PIN management
- CAPS_V2 characteristic 韌體實作
- Maintenance-safe config surface（若 Role-1 有現場調整需求）

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17: /opt/homebrew/opt/openjdk@17
- 韌體裝置：1 GW + 2 ED, Network 0
- 韌體 PR #61 (CMD 0x03/0x04) 已 merge
- 韌體 PR #62 (API Phase 0) 已 merge
- 韌體 PR #63 (CMD_V2) OPEN，有 merge conflict
