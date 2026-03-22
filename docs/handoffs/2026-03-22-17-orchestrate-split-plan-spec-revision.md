# EOD Handoff — 2026-03-22 17:00

**Date**: 2026-03-22
**Session Type**: architecture + orchestrate + spec revision + infrastructure
**Repo(s) Affected**: ble_qos_app, ble_qos_demo_V1.2m (firmware), tlae (orchestrate skill)

## Summary

6 項架構基石全部定案 + orchestrate 自動執行 17/17 TDD tasks + spec 修訂 39/49 完成 + 全域 doc size hook 建立。

## Modified Files

### orchestrate skill（`~/.claude/skills/orchestrate/`）
- `sdd-system.md` — split plan 輸出格式（目錄 + sections/）
- `orchestrate.sh` — section dispatch + split plan 偵測 + plan_file→plan_path bug fix

### 全域 hooks（`~/.claude/`）
- `scripts/check-doc-size.sh` — PreToolUse hook，所有 .md 預設 300 行上限
- `settings.json` — 新增 PreToolUse Write|Edit hook

### App repo（`ble_qos_app`）
- `docs/architecture/foundations/02-device-identity.md` — ✅ 定案：App-generated UUIDv4
- `docs/architecture/foundations/03-ble-lifecycle.md` — ✅ 定案：visible scan + 3x backoff
- `docs/architecture/foundations/06-compat-matrix.md` — ✅ 定案：code-embedded + graceful degrade
- `docs/architecture/APP_ARCHITECTURE.md` — 6/6 全部 ✅
- `docs/architecture/SPEC_REVISION_CHECKLIST.md` — 39/49 checked
- `.claude/rules/doc-size-limit.md` — 文件大小規則
- `.claude/rules/branch-hygiene.md` — PR/branch 規則
- `.claude/settings.json` — PostToolUse hook
- `CLAUDE.md` — 移除「未定案阻擋 production code」
- 17 個 TDD commits（identity migration + BLE lifecycle + compat matrix）
- PR #8 merged（identity migration），PR #9 merged（architecture docs + roster）
- 舊 plans 搬到 `docs/plans/archive/`

### 韌體 repo（`ble_qos_demo_V1.2m`）
- `docs/superpowers/specs/2026-03-19-ble-qos-mobile-app-design.md` — P0+P1+P2 修訂
- `docs/current/app_role_pages.md` — 6 處對齊修訂

### app-verify skill
- `SKILL.md` — 253→154 行，拆出 `references/tap-troubleshooting.md`
- 新增原因 C（鍵盤遮擋）+ dismiss keyboard 規則

## Key Changes

### ⚠️ ADR: orchestrate split plan 機制
- plan 不再是單一 1800 行檔案，改為 `plan.md`（索引）+ `sections/section-NN-*.md`（≤300 行）
- sub-agent 只讀對應 section file
- 首次實戰：17/17 tasks 全部成功，164 tests passing

### ⚠️ ADR: 全域 doc size hook
- PreToolUse 攔截所有 .md 的 Write/Edit
- 預設上限 300 行，特定路徑有更嚴的限制
- `archive/` 路徑豁免
- 原先用白名單（只列已知路徑）→ 改為黑名單 + 預設上限（所有 .md 都受保護）

### 實機驗證
- Scanner 4 devices ✅、Device Screen ✅、Dashboard telemetry ✅
- 發現鍵盤遮擋問題 → 加入 dismiss keyboard 規則到 skill

## Immediate

1. **拆 976 行 spec 文件** — `ble-qos-mobile-app-design.md` 超過 300 行上限
2. **Roster 端到端測試** — GW 連線 + PEER_ROLE handshake + CMD 0x03/0x04
3. **韌體 repo push** — spec + role-pages 修訂已 commit 未 push

## Backlog

- Spec 修訂剩 10 個 checkbox（CAPS_V2 UUID、CMD_V2、App Store compliance）
- orchestrate `sdd-system.md` 363 行，可拆 EDIT_BLOCK examples 到 references/
- App API for AI Agent
- Admin tab — GW_CFG editor + PIN management

### Key Insights

- **Doc size hook 用黑名單 + 預設上限，不用白名單** — 白名單漏掉 `docs/superpowers/specs/` 等路徑，840 行 spec 直接放行。預設 300 行 + 特定路徑覆蓋才能確保不漏
- **plan.md 也不應例外** — 「人類 review 用所以不限」是錯的。人類也不會看完 1500 行。plan.md 應該是索引，細節在 sections/
- **adb tap 前一律 dismiss keyboard** — Flutter 有 TextField 的頁面，tap 可能觸發 focus → 鍵盤彈出遮擋後續 tap。每次 tap 前 `adb shell input keyevent 4`

## Environment Notes

- Branch: `main`（App repo clean）
- 韌體 repo: `feat/api-phase1-cmd-txn-20260322_112956` 有未 push 的 spec 修訂
- 205 unit tests passing（App repo）
- 全域 hook: `~/.claude/scripts/check-doc-size.sh`（PreToolUse）
