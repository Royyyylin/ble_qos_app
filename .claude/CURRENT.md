# BLE QoS App — Current State

**最後更新：** 2026-03-23

## 架構決策 — 6/6 全部定案

詳見 `docs/architecture/APP_ARCHITECTURE.md`。

## Prototype 進度

- [x] Design Spec 全面實作（15 tasks TDD）
- [x] Device identity + BLE lifecycle + Roster + Spec 修訂 40/49
- [x] Code review 7 bug fix + PEER_ROLE UUID 修正
- [x] QosMetricsV2 parser + Dashboard 0 值 UX + Throughput
- [x] CMD_V2/CMD_RESULT/ROSTER_LIST codec + CmdV2Service
- [x] Firmware Roster UI（Add/Remove via CMD_V2 + auto ENG_UNLOCK）
- [x] GW_CFG editor + ENG_PIN_SET + GW_CFG_VERSION notify
- [x] FW_VERSION + DEVICE_INFO AppBar（30s uptime 刷新）
- [x] Engineer countdown warning + Lock Now + Settings 導航
- [x] Roster MAC-based matching（scan ↔ firmware roster）
- [x] 實機驗證全通過（含 Roster Add/Remove CMD_V2）
- [x] app-verify skill 更新（架構優先 + screenshot loop + Maestro roadmap）

## 下一步

1. ENG_UNLOCK GATT_INSUFFICIENT_AUTHORIZATION — 待重測
2. Provisioning / Audit screen 驗證
3. App API for AI Agent
4. Maestro + Semantics identifier
5. Spec 修訂剩 9 個 checkbox

## Backlog

- CAPS_V2 CBOR（韌體先實作）
- Android Play Data safety / iOS App Store review
- Role-1 maintenance-safe config surface
- Audit CSV export（Phase 2 stub）

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Java 17: /opt/homebrew/opt/openjdk@17
- 221 unit tests passing
- 韌體 1.2.0+0（PR #62-#73 merged，4 DK flash）
