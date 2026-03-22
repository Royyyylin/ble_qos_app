# 6. App/FW 相容矩陣 ⏳（CAP 已定案，可開始）

## Capability Negotiation Read Order

```
連線後 →
  1. 讀 FW_VERSION（6f8a9c1b）
  2. 讀 DEVICE_INFO（6f8a9c1c）
  3. 嘗試讀 CAPS_V2（新 UUID）
     ├─ 存在 → versioned capability negotiation（CBOR: id + version）
     └─ 不存在 → fallback 讀 CAP v1（6f8a9c19，bitmask）
  4. 對照相容矩陣 → 決定顯示哪些功能
  5. 不相容 → graceful degrade（灰色 + 提示「需要韌體 vX.Y」）
```

## 大廠做法

- **Meraki**：已發佈 major version 只做 backward-compatible 變更；breaking change 走 deprecation/sunset
- **SmartThings**：capability = capabilityId + version；未知 capability 不顯示即可
- **Azure DTDL**：v2/v3 混用逐步遷移

## 規則

- App 不得假設韌體版本，必須動態讀取
- 功能開關由 capability + version 推導，不靠 route 參數硬傳
- `showControlTab` / `showAdminTab` 由 `role + capability + version` 三者共同決定
- 未知 capability → graceful ignore（不 crash、不阻擋其他功能）
- 不相容功能 → 只關閉該 feature，不拖垮整體

## 待定細節

- [ ] CAPS_V2 的 UUID 分配
- [ ] CBOR schema 定義（`[{id: string, version: int}, ...]`?）
- [ ] 相容矩陣是寫死 App code 還是可遠端更新？
- [ ] graceful degradation 的 UI 具體長什麼樣？
