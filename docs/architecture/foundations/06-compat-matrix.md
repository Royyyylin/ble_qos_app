# 6. App/FW 相容矩陣 ✅

## Capability Negotiation Read Order

```
連線後 →
  1. 讀 FW_VERSION（6f8a9c1b）→ 解析 major.minor.patch.build
  2. 讀 DEVICE_INFO（6f8a9c1c）→ 取 role + hw_rev
  3. 嘗試讀 CAPS_V2（新 UUID，待韌體實作）
     ├─ 存在 → versioned capability negotiation（CBOR: id + version）
     └─ 不存在 → fallback 讀 CAP v1（6f8a9c19，bitmask）
  4. 對照相容矩陣 → 決定顯示哪些功能
  5. 不相容 → graceful degrade（灰色 + 提示「需要韌體 vX.Y」）
```

## 決策

### 相容矩陣儲存方式

**寫死在 App code**（不做遠端更新）。理由：
- Enterprise field app，裝置數有限（不是 consumer 規模）
- App 版本和韌體版本是已知組合（不像 consumer app 面對無數裝置型號）
- 遠端更新增加複雜度但 ROI 低
- 大廠做法：Meraki 已發佈版本只做 backward-compatible，breaking change 走新 version

### 矩陣格式

```dart
/// lib/core/capability/compat_matrix.dart
const compatMatrix = {
  'qos_monitoring': CompatEntry(minFw: '1.2.0', capBit: 0x01, capsV2Id: 'qos_monitoring'),
  'roster_management': CompatEntry(minFw: '1.2.0', capBit: 0x02, capsV2Id: 'roster_management'),
  'ha_failover': CompatEntry(minFw: '1.3.0', capBit: 0x04, capsV2Id: 'ha_failover'),
  'control_profile': CompatEntry(minFw: '1.2.0', capBit: 0x08, capsV2Id: 'control_profile'),
};
```

### Graceful Degradation UI

| 情境 | UI 行為 |
|------|---------|
| Capability present + version OK | 正常顯示 tab/feature |
| Capability present + version too old | Tab 顯示但灰色 + 「需要韌體 vX.Y」tooltip |
| Capability absent | Tab 隱藏 |
| Unknown capability (CAPS_V2 有但 App 不認識) | Graceful ignore（不 crash、不阻擋其他功能） |
| CAPS_V2 不存在 | Fallback 到 CAP v1 bitmask，功能集可能較少 |

### CAPS_V2 規劃

- **UUID**：待韌體分配（建議 `6f8a9c1e`，接在 GW_CFG_VERSION `6f8a9c1d` 之後）
- **格式**：CBOR array `[{id: string, version: int}, ...]`
- **韌體 backlog**：等 App 端 parser 準備好後，韌體再實作

## 規則

- App 不得假設韌體版本，必須動態讀取
- 功能開關由 capability + version 推導，不靠 route 參數硬傳
- `showControlTab` / `showAdminTab` 由 `role + capability + version` 三者共同決定
- 未知 capability → graceful ignore（不 crash、不阻擋其他功能）
- 不相容功能 → 只關閉該 feature，不拖垮整體

## 大廠做法

- **Meraki**：已發佈 major version 只做 backward-compatible 變更；breaking change 走 deprecation/sunset
- **SmartThings**：capability = capabilityId + version；未知 capability 不顯示即可
- **Azure DTDL**：v2/v3 混用逐步遷移
