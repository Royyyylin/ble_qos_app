# BLE QoS Field Tool

現場工程工具 APP，給工程師安裝、巡檢、維修 nRF52833 GW/ED 設備用。圖形化監控在 Central 另外做。

## APP 定位：現場工程工具

- **安裝驗收** — 裝完看 Pass/Warning/Fail，確認 BLE 連線品質合格
- **定期巡檢** — 巡廠時快速掃一圈確認所有 GW/ED 狀態
- **故障排除** — Central 告警後，帶手機到現場診斷問題 ED
- **參數調整** — 工程模式改 Profile / PHY / TX Power / Interval
- **設備管理** — 改 Role、換 PIN、重啟

## 安裝合格標準（APP 端判定，門檻值在 Dart code）

| 指標 | ✅ PASS | ⚠ WARNING | ❌ FAIL |
|---|---|---|---|
| RSSI | > -65 dBm | -65 ~ -85 | < -85 |
| PDR | > 95% | 85~95% | < 85% |
| Latency | < 20ms | 20~50ms | > 50ms |
| Jitter | < 5ms | 5~15ms | > 15ms |

GW 韌體只送 raw 數值，Pass/Warning/Fail 判定在 APP 和 Central 各自套門檻。

## Tech Stack

- **Flutter 3.41.2** | Dart 3.11
- **State:** flutter_riverpod + riverpod_annotation
- **Navigation:** go_router (3 pages: Scan → Dashboard → Engineering)
- **BLE:** flutter_blue_plus 1.32
- **Target:** Android (Samsung SM-S9160, wireless ADB `192.168.18.10:33331`)

## Commands

```bash
source ~/.bashrc                          # Load env (JAVA_HOME, ANDROID_HOME, PATH)
cd /mnt/c/roy-ncs/ble_qos_app
flutter pub get                           # Install deps
flutter test                              # Run all tests (31 passing)
flutter analyze                           # Must pass with zero issues
flutter build apk --debug                 # Build debug APK
flutter run -d 192.168.18.10:33331        # Deploy to phone
```

## Project Structure

```
lib/
├── protocol/        # GATT: uuids.dart, models.dart, codec.dart (binary encode/decode)
├── core/ble/        # BLE connection, scanner, permissions
├── theme/           # [NEW] auto_theme.dart, engineer_theme.dart
├── providers/       # [NEW] topology_provider.dart, scan_provider.dart (addr→name cache)
├── widgets/         # [NEW] info_tooltip.dart (ⓘ + bottom sheet)
├── data/            # [NEW] tooltip_content.dart (30+ tooltip constants)
└── pages/           # [NEW] scan_page, dashboard_page, engineering_page
test/protocol/       # codec_test.dart
```

## Architecture Rules

- Riverpod StateNotifier for all state. Do NOT introduce BLoC, GetX, or Provider.
- go_router for navigation. No Navigator.push.
- UUIDs use 128-bit full format for flutter_blue_plus compatibility.
- BLE scan filter is Dart-side (name prefix `FGW_` / `FED_`), not platform-side.
- Binary codec uses little-endian ByteData. RSSI is signed int8.
- Fonts: JetBrains Mono (data/values), IBM Plex Sans (UI text).
- Extract widgets into separate classes, not helper methods.
- `const` constructors wherever possible. Trailing commas on all parameter lists.

## Dual Theme System

Unified light background `#F5F3F0`. ENGINEER mode distinguished by deep red header only:
- **mode == 0 → AUTO:** Normal header, cyan/green accents
- **mode == 1 → ENGINEER:** Deep red header `#8B1025` white text, red accents `#D42040`

Use Riverpod provider watching `mode`. Consider `AnimatedTheme` for smooth transition.

## What NOT To Do

- Do NOT rewrite V1 protocol/ or core/ble/ — they work and have passing tests.
- Do NOT modify .pbxproj or AndroidManifest.xml unless explicitly asked.
- Do NOT add new packages without asking first.
- Do NOT use amber/orange for engineer mode — use red `#D42040` only.
- Do NOT put engineering parameters (credits, TP mode) on Dashboard — those belong on Page 3.

## Key References

- @UI_REDESIGN_SPEC.md — Full design spec: page layouts, color tables, all tooltip content, GATT mapping
- @docs/mockups/ — HTML interactive prototypes (open in browser to see visual targets)

## Known Issues

- Flutter 3.41: `Radio.groupValue`/`Radio.onChanged` deprecated → use custom InkWell+Icon
- WSL2 → `/mnt/c/` write speed is slow; first build takes 3-10 min
- `flutter doctor` may need env vars re-sourced each terminal session
