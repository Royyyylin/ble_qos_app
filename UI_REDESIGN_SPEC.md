# BLE QoS Tool — UI Redesign Specification

## Overview

Handoff spec for V2 UI of the Flutter BLE QoS field tool. Covers three-page architecture, AUTO/ENGINEER modes, color system, typography, components, tooltips, and GATT mapping.

**Tech stack:** Flutter 3.41.2, flutter_blue_plus, Riverpod, go_router
**Hardware:** nRF52833 — roles: FGW (Gateway), FED (End Device)

---

## Three Pages

```
Page 1: Scan       → Discover FGW, show nested FED topology
Page 2: Dashboard  → Pass/Fail summary cards, expandable metric details
Page 3: Engineering → PIN-locked control panel for manual tuning
```

Navigation: Scan → tap GW → Dashboard → 🔒 PIN → Engineering → LOCK & EXIT → Dashboard → ‹ back → Scan

---

## Unified Light Theme

All pages: light bg `#F5F3F0`. ENGINEER mode = deep red header `#8B1025` + red accents `#D42040`. No dark mode.

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| bg | `#F5F3F0` | Page background |
| bg-card | `#FFFFFF` | Cards |
| bg-tile | `#FAF8F5` | Metric tiles |
| border | `#E2DDD6` | Borders |
| text-primary | `#1A1A1A` | Main text |
| text-secondary | `#5C5C5C` | Labels |
| text-dim | `#9A9088` | Hints |
| green | `#1B8A4A` | PASS, online |
| green-bg | `#E6F7ED` | Green tint |
| red | `#D42040` | FAIL, engineer accent |
| red-header | `#8B1025` | Engineer header |
| red-bg | `#FFF0F2` | Red tint |
| amber | `#B87A00` | WARNING |
| amber-bg | `#FFF6E0` | Amber tint |
| cyan | `#007A8C` | GW accent, config values |

### Thresholds (APP-side judgment, GW sends raw only)

| Metric | ✅ PASS | ⚠ WARNING | ❌ FAIL |
|--------|---------|-----------|--------|
| RSSI | > -65 dBm | -65 ~ -85 | < -85 |
| PDR | > 95% | 85~95% | < 85% |
| Latency | < 20ms | 20~50ms | > 50ms |
| Jitter | < 5ms | 5~15ms | > 15ms |

---

## Typography

- Data/values: **JetBrains Mono** 600-700, 13-20px
- Labels: **JetBrains Mono** 400, 8-12px
- UI text/tooltips: **IBM Plex Sans** 400-600, 13px

---

## Page 1: Scan

- Header: `BLE QoS Field Tool` + green pulsing SCANNING dot
- RSSI legend bar with ⓘ
- GW cards: cyan left border, name + GATEWAY tag + RSSI + ED count + RSSI bar
- Expandable FED tree: connector line, dot (green/gray), name, RSSI, Profile badge
- "tap gateway to connect →"

## Page 2: Dashboard

### Collapsed (default): Pass/Fail per ED
- 36px health dot: ✓ green / ! amber / ❌ red / — gray
- Name + "PASS — 全部合格" or "WARNING — RSSI / Jitter"
- Profile mini badge + ▶ expand arrow

### Expanded (tap): 3×2 metric grid (RSSI, PDR, Latency, PHY, TX, Jitter)

### AUTO mode: cyan GW border, MODE=AUTO green, 🔒 ENGINEERING MODE button
### ENGINEER mode: red header `⚠ ENGINEER MODE` + timer, red borders, MANUAL tags, 🔓 OPEN CONTROLS

## Page 3: Engineering

- Red header + timer (same as Page 2 engineer)
- Target selector: GW or ED[n]
- 3 collapsible sections (red left border):

**CTRL** (9B, `0x2A21`): Profile, PHY, TX Power, Interval, TP Mode → WRITE CTRL / READ
**GW CONFIG** (8B, `6f8a9c10`): TP Mode, Phone Log, Credits A/C/R → WRITE GW_CFG / READ
**ADMIN**: Role (triggers reboot), Change PIN, REBOOT (solid red danger button)

Bottom: 🔓 LOCK & EXIT

---

## Tooltip System

ⓘ 16px button → bottom sheet (drag handle, cyan title, body). Content covers all metrics, modes, Profile, PHY, TX Power, Interval, TP Mode, Phone Log, Credits, Role, PIN, Reboot, Timeout.

### Tooltip Content

| Target | Title | Key Content |
|--------|-------|-------------|
| RSSI | RSSI 信號強度 | > -65 強(綠), -65~-85 中(橘), < -85 弱(紅) |
| PDR | PDR 封包送達率 | > 95% 良, 85~95% 注意, < 85% 差 |
| Latency | 延遲 | < 20ms 低, 20~50ms 正常, > 50ms 高 |
| Jitter | 延遲抖動 | < 5ms 穩定, 5~15ms 波動, > 15ms 不穩 |
| PHY | 無線電模式 | 2M 最快最短, 1M 平衡, Coded S2/S8 最遠 |
| TX Power | 發射功率 | -40~+8 dBm, 越高越遠越耗電 |
| Profile | QoS 策略 | FAST 2M/15ms, BAL 1M/30ms, ROBUST Coded/50ms |
| Mode AUTO | 模式 | 韌體自動調整 QoS |
| Mode ENG | 工程模式 | 手動控制, 5分鐘 timeout |
| Interval | 連線間隔 | 7.5~4000ms, 須為 1.25ms 整數倍 |
| TP Mode | 吞吐量測試 | 測試用, 完成後關閉 |
| Phone Log | 推送開關 | ON=即時 notify, OFF=手動 REFRESH |
| Credits A/C/R | 流量控制 | ACL/CONN/RETX 信用額度, 預設 3 |
| Role | 角色 | GW/ED/REPEATER, 切換觸發重啟 |
| Change PIN | PIN 碼 | 4~8 位數字, 預設 1234, 存 flash |
| Reboot | 重啟 | 斷開所有 BLE 連線, 需重新掃描 |
| Timeout | 倒數計時 | 5 分鐘無操作自動鎖定, WRITE 重置計時 |

---

## GATT Service `0x1820`

| Char | UUID | R/W | Bytes |
|------|------|-----|-------|
| STATUS | `0x2A1D` | R/N | varies |
| METRICS | `0x2A23` | R/N | varies |
| CTRL | `0x2A21` | R/W | 9 |
| GW_CFG | `6f8a9c10` | R/W | 8 |
| ENG_UNLOCK | `6f8a9c11` | W | 4 |
| CMD | `0x2A20` | W | 2 |
| ED_COUNT | `6f8a9c14` | R/N | 1 |
| ED_LIST | `6f8a9c15` | R/N | N×9 |

### Multi-ED format
```
STATUS:  [ed_idx:1][profile:1][zone:1][mode:1][connected:1]
METRICS: [ed_idx:1][rssi:1][pdr:1][latency:2][phy:1][tx_pwr:1][jitter:2][unused:1]
CTRL:    [ed_idx:1][profile:1][phy:1][tx_pwr:1][interval:2][tp_mode:1][reserved:2]
ED_LIST: [ed_idx:1][addr_type:1][addr:6][connected:1] per slot
```

### Engineer Unlock Flow
1. Write 4-byte PIN to ENG_UNLOCK → 2. Read STATUS check mode==1 → 3. Start 5min countdown → 4. Each WRITE resets timer → 5. Timeout → mode back to 0

---

## Implementation Priorities

1. Theme system — unified light + engineer red header
2. Tooltip widget — reusable ⓘ + bottom sheet
3. Page 1 Scan — GW cards + FED tree
4. Page 2 Dashboard — Pass/Fail collapsed cards + dual mode
5. Page 3 Engineering — collapsible form sections
6. Integration — topology provider + notify subscription

## HTML Mockups

| File | Description |
|------|-------------|
| `docs/mockups/page1_scan.html` | Scan (light, GW+FED tree) |
| `docs/mockups/page2_dashboard_auto.html` | Dashboard AUTO (Pass/Fail) |
| `docs/mockups/page2_dashboard_engineer.html` | Dashboard ENGINEER (red header) |
| `docs/mockups/page3_engineering.html` | Engineering (red header) |
