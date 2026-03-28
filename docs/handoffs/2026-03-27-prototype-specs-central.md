---
date: 2026-03-27
time: "23:59"
type: architecture + prototype + specs + cross-repo
---

# EOD Handoff — 2026-03-27

## Summary

完成 App 端 HTML prototype（Scanner + Device Screen 5 tabs + Roster per-ED metrics 方案 B 定案），建立 App Repo Scope 定案文件，並與韌體 AI 協作完成 Central Device Metadata 專案（identity contract、telemetry-schema、auth-sync-contract、failover-policy、implementation-plan、MVP vertical slice）。三個 repo 的 spec package 全部封板，進入 Phase 3 implementation。

## Modified Files

### App repo（`ble_qos_app`，branch: `feat/prototype-roster-dashboard-update`）

**Prototype：**
- `docs/prototype/device.html` — Device Screen 5-tab prototype（Dashboard=GW info, Roster=per-ED metrics, HA, Control, Admin）
- `docs/prototype/roster-v2.html` — 方案 B 定案：per-ED metrics 列表，4 欄 QoS + 3 欄 config，字體加大，單位右置
- `docs/prototype/roster-compare.html` — A/B/C 三方案比較頁

**Specs：**
- `docs/specs/app-scope.md` — App Repo Scope 定案（index + 摘要 + open questions 分類）
- `docs/specs/app-scope/01-must-own.md` — 必負責範圍
- `docs/specs/app-scope/02-non-goals.md` — 不負責範圍 + 10 條反模式
- `docs/specs/app-scope/03-identity-contract.md` — Canonical identity 對齊 + 三層分離
- `docs/specs/app-scope/04-local-state.md` — Local/UI state 清單
- `docs/specs/app-scope/05-interface-contract.md` — 輸入/輸出契約 + 介面切分
- `docs/specs/app-scope/06-alias-qos-role.md` — Alias/Rename、QoS 呈現、Role 規則

**其他：**
- `.claude/CURRENT.md` — 更新進度

### Central repo（`central-device-metadata`，main branch）

韌體 AI + App AI 協作完成：
- `docs/specs/telemetry-schema.md` — v1.0 定案（3 critical fixes + 3 small fixes）
- `docs/specs/auth-sync-contract.md` → 合併為 `central-auth-sync-contract.md`（6 fixes from review）
- `docs/specs/failover-policy.md` — 韌體 AI 版本採用
- `docs/specs/implementation-plan.md` — Phase A/B/C/D backlog
- `docs/specs/mvp-vertical-slice.md` — 1 ED → 1 GW → Central → App 驗收條件
- Central scaffold（FastAPI + PostgreSQL + Alembic + models）— 韌體 AI 完成

## Key Changes

1. **架構決策：Dashboard → GW info，Roster → per-ED metrics** — 原 Dashboard 的 QoS 數值本來是 aggregate（看不出哪台 ED），改成 Roster 直接列出每台 ED 的 7 項 metrics。Dashboard 改為 GW 自身資訊
2. **App Scope 定案** — 明確 App 是 human-facing interaction owner，不是 global truth source。rename 是 App 的 interaction flow，Central 是 truth owner
3. **Cross-repo spec 全部封板** — telemetry-schema、auth-sync-contract、failover-policy、implementation-plan、MVP slice 全部在 central repo main 上
4. **auth-sync-contract 重複檔案合併** — 刪除 Claude 版，統一用韌體 AI 版（更完整）

## Immediate

1. **App 端 local models / state skeleton** — 依 GPT 指令稿，做 local DB models + sync client interface + UI state models + alias flow state
2. **PR merge** — `feat/prototype-roster-dashboard-update` branch 需 merge 到 main
3. **Central Phase A3** — auth skeleton（韌體 AI 負責）

## Backlog

- HTML prototype → Flutter 遷移
- 實機驗證 persistent DB
- Maestro YAML flow
- Central Phase 3B: manual switchover
- Central Phase 3C: automatic failover

## Key Insights

- **先出 HTML prototype 再定 spec** — 看到畫面後發現 Dashboard metrics 的 aggregate 問題（看不出是哪台 ED），如果純寫 spec 不會發現這個 UX 問題
- **三邊 AI 協作的 spec 重複問題** — auth-sync-contract 出現兩份（Claude 版 + 韌體 AI 版），需要主動合併。多 AI 協作時要指定 canonical version
- **GPT 做 review + 給結構化指令很有效** — GPT 不直接寫 code/spec，但提供方向修正和指令稿，讓 Claude/韌體 AI 執行。三層分工（GPT=architect、Claude=App AI、韌體 AI=FW+Central）

## Environment Notes

- App repo: `feat/prototype-roster-dashboard-update` branch，4 commits ahead of main
- Central repo: main branch，scaffold 已建好（FastAPI + PostgreSQL + 7 tables）
- 三 repo spec package 已封板（Phase 2 complete）
