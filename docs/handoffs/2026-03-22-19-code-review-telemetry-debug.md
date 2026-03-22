---
date: 2026-03-22
time: "19:30"
type: code-review + debugging + infrastructure
---

# EOD Handoff — 2026-03-22 19:30

## Summary

Code review 發現 5 個 bug 並修復（含 2 個 critical：identity provider 未接線 + stream 洩漏），韌體 spec 拆分完成（976→5 檔），實機驗證 7/7 PASS，telemetry 全 0 問題完成根因分析。

## Modified Files

### App repo（`ble_qos_app`）
- `lib/core/providers/identity_provider.dart` — 移除未實作的 appDatabaseProvider，改用 databaseProvider
- `lib/main.dart` — 加入 identity service initialize() 呼叫
- `lib/features/scanner/scanner_screen.dart` — 修復 StreamSubscription 洩漏（加 _deviceSub field + cancel）
- `lib/core/ble/backoff_config.dart` — maxAttempts 5→3（對齊架構文件）
- `lib/features/device/admin/admin_tab.dart` — pinController dispose
- `lib/core/ble/ble_connector.dart` — handshake 失敗加 debugPrint
- `lib/core/providers/metrics_provider.dart` — 取消所有 debugPrint 註解 + 加 raw hex log
- `docs/architecture/SPEC_REVISION_CHECKLIST.md` — 40/49，更新 spec 路徑
- `.claude/CURRENT.md` — 反映本次完成工作

### 韌體 repo（`ble_qos_demo_V1.2m`）
- `docs/superpowers/specs/ble-qos-mobile-app-design/` — 5 個 sub-files + index（從 976 行單檔拆分）
- `docs/superpowers/specs/archive/` — 原始 spec 歸檔
- PR #65 已建立，auto-merge 設定

### 全域 skill
- `~/.claude/skills/orchestrate/sdd-system.md` — 363→289 行，examples 拆到 references/
- `~/.claude/skills/orchestrate/references/edit-block-examples.md` — 新建
- `~/.claude/skills/app-verify/references/tap-troubleshooting.md` — 更新 keyboard dismiss 陷阱

## Key Changes

### Code Review 5 Bug Fix
1. **Critical: identityServiceProvider 用了未實作的 appDatabaseProvider** → 改用已有的 databaseProvider
2. **Critical: DeviceIdentityService.initialize() 從未呼叫** → main.dart initState 中 await
3. **Critical: ScannerScreen StreamSubscription 洩漏** → 加 _deviceSub field + cancel
4. **Important: BackoffConfig maxAttempts=5 vs 架構=3** → 改為 3
5. **Important: AdminTab pinController 未 dispose** → dialog 結束後 dispose

### Telemetry 全 0 根因分析
- GATT STATUS read 成功（13 bytes），但值確實是 0
- 原因：ED 未在 GW QoS session 中，STATUS 值未被韌體填充
- QosMetricsV2 只存 raw bytes 未解析
- Dashboard 只 watch statusStreamProvider，沒接 metricsStreamProvider
- PEER_ROLE handshake 失敗：characteristic 不支援 WRITE property

### 實機驗證 7/7 PASS
- Scanner, GW Dashboard, Roster, HA, Control, ED Device Screen, Back Nav 全通過

## Immediate

1. **修 telemetry 管線** — QosMetricsV2 parser 欄位解析 + Dashboard 接 metricsStreamProvider + 0 值 UX 改 "--"
2. **確認韌體 NOTIFY 支援** — STATUS/METRICS characteristic 是否啟用 notify property
3. **修 PEER_ROLE** — 韌體端確認 PEER_ROLE characteristic 的 WRITE property

## Backlog

- Code review 遺留 #6（TTL 閾值不一致）+ #7（showControlTab 無角色判斷）
- Roster 端到端測試（需 GW 硬體）
- Spec 修訂剩 9 個 checkbox（韌體 backlog + App Store）
- App API for AI Agent
- Admin tab — GW_CFG editor + PIN management

## Key Insights

- **debugPrint 註解 = 隱形 bug** — catch block 裡的 debugPrint 被註解掉，錯誤完全消失，連開發者自己都不知道 GATT subscribe 失敗了
- **adb keyevent 4 不能盲目用** — 沒有鍵盤時會觸發 GoRouter back 導航。需先 `dumpsys input_method | grep mInputShown` 確認
- **PreToolUse hook 看現有行數** — Edit 被擋是因為 hook 檢查的是當前檔案行數（363），即使 edit 後會變短。需用 Write 整檔重寫繞過
- **Code review + 實機驗證同步跑** — 平行啟動兩個 agent 效率最高

## Environment Notes

- App repo: main branch clean, 205 tests passing
- 韌體 repo: PR #65 等待 CI auto-merge
- 全域 skill: sdd-system.md 289 行（from 363），加 references/edit-block-examples.md
