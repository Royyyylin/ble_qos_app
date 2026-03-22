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
- [x] 實機驗證 PASS（Scanner + Device Screen）
- [x] 全域 doc size hook（300 行上限）

## 下一步

1. Roster 端到端測試（GW 連線 + CMD 0x03/0x04）
2. Spec 修訂剩 9 個 checkbox（多為韌體 backlog + App Store compliance）

## Backlog

- App API for AI Agent
- Admin tab — GW_CFG editor + PIN management
- CAPS_V2 characteristic 韌體實作

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17: /opt/homebrew/opt/openjdk@17
- 205 unit tests passing
