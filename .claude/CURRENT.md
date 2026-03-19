# BLE QoS App — Current State

**最後更新：** 2026-03-20

## 進度

- [x] BLE 套件遷移 (flutter_reactive_ble → flutter_blue_plus)
- [x] Design Spec 全面實作（15 tasks TDD, PR #1 merged）
  - 深色科技風主題
  - 三層認證系統（PIN + session + permission guard）
  - Capability model + registry + negotiator
  - Drift SQLite DB（devices, alerts, audit_log, telemetry）
  - GoRouter 路由
  - Fleet Dashboard + device screen + provisioning + audit
- [x] Android 實機部署到 Pixel 7a
- [x] BLE 掃描權限修復（Android 16）
- [ ] 韌體端廣播封包更新（缺 manufacturer data + service UUID）
- [ ] App 端 Nordic CID filter 啟用

## 下一步（優先順序）

1. 韌體：加 manufacturer specific data 到 adv（Spec §4.5）
2. 韌體：加 QoS Service UUID 到 adv
3. App：啟用 Nordic CID filter
4. App：Device Screen 連線 + GATT 整合
5. App：Drift DB 持久化已知裝置

## 已知問題

- Android 16 BLE scan 不回傳 device name/serviceUuids（需 FINE_LOCATION + androidUsesFineLocation=true）
- 韌體廣播封包無 manufacturer data，App 無法識別 QoS 裝置
- flutter build apk 需要手動 export JAVA_HOME/ANDROID_HOME

## 測試

- 91 unit tests passing
- CI: GitHub Actions flutter analyze + test (passing)

## 環境

- Pixel 7a: 3A271JEHN05259 (Android 16, API 36)
- Android SDK: /opt/homebrew/share/android-commandlinetools
- Java 17: /opt/homebrew/opt/openjdk@17
