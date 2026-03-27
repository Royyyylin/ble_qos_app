# App Repo Scope — QoS 專案 App 邊界與責任定案

> **定案稿** — 2026-03-27
> 本文件用定案語氣。「必須」「不得」「明確禁止」不是建議。

**一句話：App repo 負責 human-facing truth，Central repo 負責 global truth，Firmware repo 負責 runtime truth。**

---

## Repo 定位

App repo 是**使用者操作介面、裝置/系統狀態呈現、與 Central/Firmware 互動流程的唯一責任邊界**。

App repo **不是** system-of-record for global metadata。
App repo **不得** 自行定義跨系統 canonical identity、assignment truth、或 failover authoritative decision。

---

## Must Own 摘要

App 必須負責：UI/UX 所有畫面（Scanner, Dashboard, Roster, HA, Control, Admin）、user interaction flows（rename, connect, add/remove, failover 操作入口）、local state/cache（DB, alias cache, telemetry snapshot）、role-aware UI gating（L1/L2/L3）、data presentation semantics（色彩分級, `--`/`N/A`, last valid retention）。

**App 是 rename flow 的 interaction owner** — 使用者在 App 裡改名、App 負責 UX/draft/pending/error handling。Central 是最終 truth owner，但 App 不是被動顯示。

## Non-Goals 摘要

App **不得**：定義跨系統 canonical identity、維護 global assignment truth、承擔 telemetry authoritative ingest、定義 Central auth policy、把 UI state 當作 runtime truth。10 條反模式見 `02-non-goals.md`。

## Identity 摘要

- GW: `gw:{gw_mac}` — ED: `ed:{ed_mac}` — **定案，不含 GW MAC**
- `ed:{gw_mac}/{ed_mac}` **已廢止**
- 三層分離：Identity（不可變）→ Assignment（failover 改這層）→ Routing（事件紀錄）

---

## 文件結構

| 子文件 | 內容 |
|--------|------|
| [01-must-own.md](app-scope/01-must-own.md) | App 必負責範圍 |
| [02-non-goals.md](app-scope/02-non-goals.md) | App 不負責範圍 + 反模式 |
| [03-identity-contract.md](app-scope/03-identity-contract.md) | Canonical identity + 三層分離 |
| [04-local-state.md](app-scope/04-local-state.md) | Local/UI state 清單 |
| [05-interface-contract.md](app-scope/05-interface-contract.md) | 輸入/輸出契約 + 介面切分 |
| [06-alias-qos-role.md](app-scope/06-alias-qos-role.md) | Alias/Rename、QoS、Role 規則 |

---

## Open Questions

### App-owned

- [ ] stale telemetry UI 呈現（灰化、時間戳、banner）
- [ ] failover 進行中 vs 完成後的 UI 狀態轉換
- [ ] discovered vs registered device 列表切換規則
- [ ] destructive actions confirm UX 一致性
- [ ] orphaned ED 的 UI 告警呈現方式
- [ ] permission denied 的 user-facing 文案與導引

### Cross-repo dependencies

- [ ] Central API 認證方式（API key / JWT / session token）→ 決定 App sync client 實作
- [ ] Central sync revision contract shape → 決定 local cache invalidation UX
- [ ] Central permission/RBAC shape → 決定 local role 與 Central token 的對應

以下不屬於 App scope：Central DB migration、firmware sequence algorithm、lease ownership、backend framework。
