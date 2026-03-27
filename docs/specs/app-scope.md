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

## 文件結構

| 子文件 | 內容 |
|--------|------|
| [01-must-own.md](app-scope/01-must-own.md) | App 必負責範圍（UI/UX、互動流程、local state、role gating、呈現語意） |
| [02-non-goals.md](app-scope/02-non-goals.md) | App 不負責範圍 + 反模式 |
| [03-identity-contract.md](app-scope/03-identity-contract.md) | Canonical identity 對齊 + 三層分離模型 |
| [04-local-state.md](app-scope/04-local-state.md) | App 核心 local/UI state 清單 |
| [05-interface-contract.md](app-scope/05-interface-contract.md) | App 輸入/輸出契約 + 介面切分 |
| [06-alias-qos-role.md](app-scope/06-alias-qos-role.md) | Alias/Rename、QoS 呈現、Role/Permission 規則 |

## Open Questions（App 專屬）

- [ ] stale telemetry 在 UI 上如何呈現（灰化、時間戳、banner）
- [ ] failover 進行中與完成後的 UI 狀態轉換
- [ ] discovered vs registered device 的列表切換規則
- [ ] destructive actions 的 confirm UX 一致性
- [ ] local cache invalidation 與 sync refresh 的 UX
- [ ] permission denied 的 user-facing 文案與導引方式
- [ ] orphaned ED 的 UI 告警呈現方式
- [ ] Central API 認證方式確定後，App sync client 實作

以下不屬於 App scope：Central DB migration、firmware sequence algorithm、lease ownership、backend framework。
