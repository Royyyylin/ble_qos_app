# EOD Handoff — 2026-03-20 01:55

## Summary

BLE QoS App 完成 Design Spec 全面實作（15 tasks TDD），從 v1 骨架升級到 spec-compliant v2。包含深色主題、三層認證、Capability 系統、Drift DB、GoRouter、Fleet Dashboard 等。同時完成 Pixel 7a 實機部署和 BLE 掃描調試。

## Modified Files

### Orchestrate 產出（PR #1, squash merged）
- `lib/core/theme/` — 深色科技風主題（app_colors.dart, app_theme.dart）
- `lib/core/auth/` — 三層認證（pin_validator, auth_session, permission_guard）
- `lib/core/capability/` — Capability model + registry + negotiator
- `lib/core/data/` — Drift SQLite DB（4 tables + 3 repositories）
- `lib/core/ble/manufacturer_data.dart` — 廣播 manufacturer data 解析
- `lib/core/gatt/gatt_uuids.dart` — 新增 Capability UUID
- `lib/main.dart` — GoRouter + dark theme
- `lib/features/scanner/` — Fleet Dashboard（EMA smoothing, stale/offline）
- `lib/features/device/` — Capability-driven device screen（Dashboard/Control/HA/Admin tabs）
- `lib/features/provisioning/` — Provisioning flow
- `lib/features/audit/` — Audit log screen
- 移除 v1 deprecated screens（gw_home, ed_home, device_list, patrol, engineer, installer）

### BLE 套件遷移（直接 commit to main）
- `pubspec.yaml` — flutter_reactive_ble → flutter_blue_plus
- `lib/core/ble/ble_scanner.dart` — 重寫掃描器
- `lib/core/ble/ble_connector.dart` — 重寫連線器
- `lib/core/ble/ble_gatt.dart` — 重寫 GATT wrapper
- `lib/core/providers/ble_provider.dart` — 移除 singleton

### Android 實機部署修復
- `android/app/src/main/AndroidManifest.xml` — BLE + location 權限
- `lib/features/scanner/scanner_screen.dart` — runtime 權限請求 + auto-scan
- `lib/core/ble/ble_scanner.dart` — 移除 UUID filter, connectable filter

## Key Changes

1. **BLE 套件遷移** — flutter_reactive_ble → flutter_blue_plus，API 從 singleton 改為 device-centric static methods
2. **Orchestrate TDD 全自動** — 15/15 tasks 通過，91 tests，Research → SDD → TDD batch
3. **Android 16 (API 36) BLE 隱私限制** — advName/serviceUuids 回傳空值，需 ACCESS_FINE_LOCATION + androidUsesFineLocation=true。⚠️ ADR candidate：Android 16 BLE scan data availability
4. **韌體缺少 manufacturer data** — 板子廣播封包不含 manufacturer specific data 和 service UUID，App 無法識別 QoS 裝置

## Immediate

1. **韌體端**：在 `role_gateway.c` / `role_end_device.c` 的廣播封包中加入 manufacturer specific data（Nordic CID 0x0059, payload: protocol_version + role + network_id）— 這是 Spec §4.5 定義的格式
2. **韌體端**：在廣播封包加入 QoS Service UUID (0x1820) 到 Complete List of 128-bit Service UUIDs AD type
3. **App 端**：韌體更新後，啟用 Nordic CID filter（ble_scanner.dart 已有 TODO）

## Backlog

- Device Screen 點擊導航（GoRouter `/device/:id`）
- 實際連線 + GATT read/write 測試
- Drift DB 整合到 scanner（持久化已知裝置）
- 深色主題微調（JetBrains Mono 字體 bundle）
- CI workflow 加 build_runner step
- 韌體端 Capability Characteristic (UUID 6f8a9c19) 實作

## Key Insights

- Android 16 BLE 隱私：`BLUETOOTH_SCAN` + `neverForLocation` = 不回傳 device name、serviceUuids。必須同時加 `ACCESS_FINE_LOCATION` 權限 + `androidUsesFineLocation: true`
- flutter_blue_plus `withServices` filter 依賴韌體在 advertising data 中明確包含 service UUID，光在 GATT table 註冊不夠
- Orchestrate SDD phase 在 domain model 太大時會 timeout（>600s），手動寫 plan 再用 `--skip-sdd --plan` 接續是可行的 workaround
- Gradle build 需要 Java 17（Java 25 太新會失敗）

## Environment Notes

- Android SDK: `/opt/homebrew/share/android-commandlinetools` (via brew)
- Java 17: `/opt/homebrew/opt/openjdk@17` (Gradle 需要)
- Pixel 7a: Serial `3A271JEHN05259`, Android 16 (API 36)
- adb: `/opt/homebrew/share/android-commandlinetools/platform-tools/adb`
- flutter build apk 需要 export JAVA_HOME + ANDROID_HOME
