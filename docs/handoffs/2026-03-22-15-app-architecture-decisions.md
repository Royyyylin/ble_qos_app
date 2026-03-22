# EOD Handoff — 2026-03-22 15:30

**Date**: 2026-03-22
**Session Type**: architecture + verification + bugfix
**Repo(s) Affected**: ble_qos_app

## Summary

App 架構 60 題討論 + 4 個合約衝突定案（CAP 格式 / GW_CFG 權限 / Engineer 逾時 / BLE plugin）。建立完整架構文件三件套（APP_ARCHITECTURE + DECISIONS_60Q + SPEC_REVISION_CHECKLIST）+ foundations/ 子資料夾。搜尋框 auto-focus bug 修復。7/7 實機驗證 PASS。

## Modified Files

### 新增（架構文件）
- `CLAUDE.md` — AI 進場讀第一個檔案，指向架構文件和合約來源
- `docs/architecture/APP_ARCHITECTURE.md` — 88 行索引：定位、合約來源、六項基石、分層目標、核心原則
- `docs/architecture/DECISIONS_60Q.md` — 60 題逐題架構決策（A~O 類別，表格格式）
- `docs/architecture/SPEC_REVISION_CHECKLIST.md` — spec 修訂追蹤（行號 + 衝突 + checkbox）
- `docs/architecture/foundations/01-capability-format.md` — ✅ CAP additive migration
- `docs/architecture/foundations/02-device-identity.md` — ⏳ stable ID hierarchy
- `docs/architecture/foundations/03-ble-lifecycle.md` — ⏳ 前景掃描 + 任務型連線
- `docs/architecture/foundations/04-timeout-error.md` — ✅ 5 timeout + 7 error
- `docs/architecture/foundations/05-auth-session.md` — ✅ session-based + C2/C3
- `docs/architecture/foundations/06-compat-matrix.md` — ⏳ negotiation read order

### 修改
- `lib/features/scanner/scanner_screen.dart` — 搜尋框 auto-focus bug fix（GestureDetector + FocusScope.unfocus）
- `.claude/CURRENT.md` — 更新為架構決策進度

### Skill 更新
- `~/.claude/skills/app-verify/SKILL.md` — 新增 Code-First 座標計算原則（不猜座標，從 code 讀 layout）

## Key Changes

### ⚠️ ADR: 4 個合約衝突定案
- **C1 CAP 格式**：Additive migration — CAP v1 (6f8a9c19) 保留 bitmask fallback，新增 CAPS_V2 CBOR。理由：符合 additive-only 原則 + 大廠做法（SmartThings/Meraki/Azure DTDL）
- **C2 GW_CFG 權限**：Role-1 唯讀，Role-2 可寫。理由：韌體 engineer_unlock prerequisite (ble_api:248)
- **C3 Engineer 逾時**：5 分鐘 + UX guardrail。理由：對齊韌體 QOS_ENG_UNLOCK_TIMEOUT_MS (ble_api:304)
- **C4 BLE plugin**：flutter_blue_plus

### 60 題架構討論
- 用戶開 4 個 agent 分析 Apple / Google / SmartThings / Cisco Meraki 做法
- 涵蓋：產品定位、BLE 連線、GATT 協議、狀態管理、資料層、認證、Capability、導航、UI/UX、錯誤處理、測試、效能、安全、部署、韌體依賴

### 搜尋框 auto-focus bug
- 從 Device 頁面返回 Scanner 時鍵盤自動彈出
- 修法：GestureDetector 包 Scaffold + FocusScope.of(context).unfocus()

### app-verify skill 更新
- 不猜座標，從 widget code 讀 layout 結構 → 用裝置 density 換算 dp → px
- sips -Z 800 的陷阱：縮的是最長邊不是寬度

## Immediate

1. 定案 **#2 裝置 stable ID** — identity hierarchy 方向已定（device_identity > provisioning_id > transport_id），需要定：生成方式、韌體 characteristic、scan model 改法
2. 定案 **#6 相容矩陣** — CAPS_V2 UUID、CBOR schema、degradation UI
3. 定案 **#3 BLE lifecycle** — 背景恢復機制、scan TTL、重連狀態機
4. 開始執行 spec 修訂（SPEC_REVISION_CHECKLIST.md checkbox）

## Backlog

- 實機測試 Roster Connect/Disconnect（韌體 PR #61 已 merge）
- App API for AI Agent（待確定使用場景）
- CAPS_V2 characteristic 韌體實作
- Maintenance-safe config surface（若 Role-1 有現場調整需求）
- Admin tab — GW_CFG editor + PIN management
- 韌體 PR #63 CMD_V2 有 merge conflict 需解

### Key Insights

- **合約衝突要先收斂再寫 code**：4 個 spec/韌體文件衝突如果不先定案，所有 capability/version/fallback 邏輯都會漂移。先定案再實作
- **大廠做法是 additive migration，不是 in-place rewrite**：SmartThings/Meraki/Azure DTDL 都保留舊版、新增新版，不改既有 UUID 語意。這和 spec 自己的 additive-only 原則一致
- **權限模型以韌體 authority 為準**：App 文件的權限定義如果和韌體不一致，等於在寫假的權限模型。先對齊 firmware，再談 UX 細化
- **app-verify 座標計算要從 code 出發**：不要猜截圖座標，從 widget code 讀 layout（dp 值）→ 乘以 density 得到 pixel 座標。Flutter 元件高度是固定的 dp 值

## Environment Notes

- Branch: `feat/gw-roster-ed-selection`
- 10 commits ahead of last EOD (`6e90c8f`)
- 工作樹乾淨
- 韌體 PR #61 (CMD 0x03/0x04) 已 merge
- 韌體 PR #62 (API Phase 0) 已 merge
- 韌體 PR #63 (CMD_V2) OPEN，有 merge conflict
