# BLE QoS App — Current State

**最後更新：** 2026-03-26

## 架構決策 — 6/6 全部定案 + 架構對齊完成

詳見 `docs/architecture/APP_ARCHITECTURE.md`。

## Prototype 進度

- [x] Design Spec 全面實作 + Code review 修正
- [x] CMD_V2/CMD_RESULT/ROSTER_LIST + CmdV2Service
- [x] CAPS_V2 CBOR parser + HA standalone mode
- [x] FW_VERSION + DEVICE_INFO + GW_CFG_VERSION
- [x] Dashboard polling 2s + last valid + Throughput N/A
- [x] Roster MAC matching + Connect/ConnectAll/Remove
- [x] Auth countdown warning + Lock Now + PIN secure storage
- [x] Persistent DB (NativeDatabase File)
- [x] BleError 7-type taxonomy + classified error screen
- [x] BLE lifecycle: 2-stage TTL + disconnect on leave/background
- [x] Maestro 安裝 + Semantics identifiers
- [x] 237 tests, 0 analyze warnings

## 下一步

1. 韌體 STATUS 長時間回 0 問題 — 等韌體診斷
2. PR #10 merge 到 main
3. 實機驗證 persistent DB
4. Maestro YAML flow 取代 adb tap
5. PinValidator 整合（Phase 2）

## Backlog

- Provisioning networkId（韌體不支援）
- Android Play Data safety / iOS App Store
- 更多 widget Semantics identifier

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17 / Maestro 2.3.0 / Claude Code 2.1.84
- 韌體 1.2.0+0（PR #62-#75 merged，4 DK flash）
