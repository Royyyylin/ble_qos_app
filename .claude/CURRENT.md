# BLE QoS App — Current State

**最後更新：** 2026-03-22

## 架構決策 — 6/6 全部定案

詳見 `docs/architecture/APP_ARCHITECTURE.md`。

## Prototype 進度

- [x] Design Spec 全面實作（15 tasks TDD）
- [x] Device identity migration（UUIDv4 stable ID）
- [x] BLE scan lifecycle + compat matrix
- [x] GW Roster ED 選擇 + 8 bug fix
- [x] Spec 修訂 40/49 complete
- [x] 實機驗證 7/7 PASS（Scanner + GW + Roster + HA + Control + ED + Back Nav）
- [x] 全域 doc size hook（300 行上限）
- [x] Code review 5 bug fix（identity init, stream leak, backoff, pin dispose）

## 下一步

1. 修 telemetry 管線（QosMetricsV2 parser + Dashboard 接線 + 0 值 UX）
2. 確認韌體 NOTIFY/WRITE property（STATUS, METRICS, PEER_ROLE）
3. Code review 遺留 #6 TTL + #7 showControlTab

## Backlog

- Roster 端到端測試（需 GW 硬體）
- Spec 修訂剩 9 個 checkbox（韌體 backlog + App Store）
- App API for AI Agent
- Admin tab — GW_CFG editor + PIN management
- CAPS_V2 characteristic 韌體實作

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17: /opt/homebrew/opt/openjdk@17
- 205 unit tests passing
