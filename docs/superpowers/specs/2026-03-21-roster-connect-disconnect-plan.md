# Roster Connect/Disconnect — App 端實作計畫

**Date**: 2026-03-21

## 前提：韌體 CMD 介面

APP 透過 CMD characteristic (0x2A20) 發送命令控制 GW↔ED 連線。

| CMD | Opcode | Payload | 說明 |
|-----|--------|---------|------|
| CONNECT_ED | 0x03 | `[0x03, addr_type(1), addr(6)]` = 8 bytes | GW 掃描並連接指定 ED |
| DISCONNECT_ED | 0x04 | `[0x04, ed_idx(1)]` = 2 bytes | GW 斷開指定 slot 的 ED |

APP 需要 ED 的 BLE address，來源：Scanner 的 `ScannedDevice.id`（MAC address 字串）。

## 現有資源

- `ED_LIST` characteristic (0x6f8a9c1a) — 讀取 GW 已連線的 ED 列表（9 bytes/entry: ed_idx + addr_type + addr[6] + connected）
- `ED_COUNT` characteristic (0x6f8a9c18) — 已連線 ED 數量
- `ENG_UNLOCK` (0x6f8a9c11) — CMD 寫入前需先解鎖

---

## 改動計畫

### T1: GattUuids 新增常數

**檔案**: `lib/core/gatt/gatt_uuids.dart`

```dart
static const String edList = '6f8a9c1a-...';  // ED_LIST read
static const String edCount = '6f8a9c18-...'; // ED_COUNT read
```

### T2: CmdCode 新增 opcode + payload builder

**檔案**: `lib/core/gatt/gatt_structs.dart`

```dart
class CmdCode {
  static const int reboot = 0x01;
  static const int setMaxEd = 0x02;
  static const int connectEd = 0x03;
  static const int disconnectEd = 0x04;
}

/// Build CMD 0x03 payload: [0x03, addr_type, addr[6]]
Uint8List buildConnectEdCmd(String macAddress) { ... }

/// Build CMD 0x04 payload: [0x04, ed_idx]
Uint8List buildDisconnectEdCmd(int edIndex) { ... }
```

### T3: EdListEntry parser

**檔案**: `lib/core/gatt/gatt_structs.dart`

```dart
class EdListEntry {
  final int edIndex;
  final int addrType;
  final String address;  // "AA:BB:CC:DD:EE:FF"
  final bool connected;

  static const int entrySize = 9;

  static List<EdListEntry> parseList(Uint8List data) { ... }
}
```

### T4: GW ED 連線 Provider

**檔案**: `lib/core/providers/ed_roster_provider.dart`（修改）

```dart
/// 從 GW 的 ED_LIST characteristic 讀取已連線 ED。
/// 取代目前用 indexed STATUS notify 推算的方式。
final gwEdListProvider = StreamProvider.autoDispose<List<EdListEntry>>((ref) async* {
  // Initial read + subscribe ED_LIST notify
});
```

更新 `edRosterProvider` 改用 `gwEdListProvider` 判斷 ED 是否連上 GW（比對 ScannedDevice.id 和 EdListEntry.address）。

### T5: CMD 寫入 Service

**檔案**: `lib/core/gatt/gatt_cmd_service.dart`（新增）

```dart
class GattCmdService {
  final BleGatt gatt;

  /// Send CMD 0x03: tell GW to connect to specified ED
  Future<void> connectEd(String edMacAddress) async {
    final payload = buildConnectEdCmd(edMacAddress);
    await gatt.writeNoResponse(GattUuids.cmd, payload);
  }

  /// Send CMD 0x04: tell GW to disconnect specified ED slot
  Future<void> disconnectEd(int edIndex) async {
    final payload = buildDisconnectEdCmd(edIndex);
    await gatt.writeNoResponse(GattUuids.cmd, payload);
  }
}
```

### T6: EdRosterTab UI — Connect/Disconnect 按鈕

**檔案**: `lib/features/device/roster/ed_roster_tab.dart`（修改）

每個 ED tile 的 trailing 改為：

| ED 狀態 | 按鈕 | 動作 |
|---------|------|------|
| 未連線 GW | `[Connect]` 藍色 | 發送 CMD 0x03 (CONNECT_ED) |
| 已連線 GW | `[Disconnect]` 紅色 | 發送 CMD 0x04 (DISCONNECT_ED) |

按鈕按下後 disable + spinner，等 ED_LIST notify 更新後恢復。

### T7: ENG_UNLOCK 解鎖流程

**前置條件**: CMD 寫入需要先解鎖 ENG_UNLOCK。

**選項 A（推薦）**: 連線 GW 時自動解鎖（固定 PIN 或從設定讀取）
**選項 B**: Roster tab 首次操作時彈出 PIN 輸入對話框

---

## 資料流

```
User taps [Connect] on ED-Alpha
    ↓
EdRosterTab → GattCmdService.connectEd("AA:BB:CC:DD:EE:FF")
    ↓
BleGatt.writeNoResponse(CMD, [0x03, addr_type, addr[6]])
    ↓
GW firmware: 掃描 → 連接 AA:BB:CC:DD:EE:FF
    ↓
GW: ED_LIST notify 更新（ED-Alpha connected=1）
    ↓
gwEdListProvider 更新 → edRosterProvider 更新
    ↓
EdRosterTab 自動重建：ED-Alpha 顯示 [Disconnect] + Online badge
```

## 檔案清單

| 檔案 | 動作 |
|------|------|
| `lib/core/gatt/gatt_uuids.dart` | 新增 edList, edCount UUID |
| `lib/core/gatt/gatt_structs.dart` | 新增 CmdCode 0x03/0x04 + EdListEntry parser |
| `lib/core/gatt/gatt_cmd_service.dart` | NEW — CMD 寫入封裝 |
| `lib/core/providers/ed_roster_provider.dart` | 改用 gwEdListProvider 判斷連線狀態 |
| `lib/features/device/roster/ed_roster_tab.dart` | 加 Connect/Disconnect 按鈕 + 操作邏輯 |
| `test/gatt_structs_test.dart` | EdListEntry parser + CMD payload 測試 |
| `test/providers/ed_roster_provider_test.dart` | gwEdListProvider 測試 |
| `test/features/device/roster/ed_roster_tab_test.dart` | 按鈕狀態切換測試 |

## 依賴

- 韌體實作 CMD 0x03 + CMD 0x04
- 韌體 ED_LIST characteristic 在 ED 連線/斷線時送 notify
- ENG_UNLOCK PIN 確認（目前預設值或需要用戶輸入）
