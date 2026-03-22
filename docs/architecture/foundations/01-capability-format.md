# 1. Capability 格式統一 ✅

**決策**：Additive migration — 不改既有 UUID 語意

```
CAP v1 (6f8a9c19)     → 保留為 1-byte bitmask（backward-compatible fallback）
CAPS_V2（新 UUID 待定）→ 新增 CBOR characteristic（正式 capability contract）
```

## App 連線讀取順序

1. 讀 `FW_VERSION` / `DEVICE_INFO`
2. 嘗試讀 `CAPS_V2`（CBOR: `[{id: "qos_monitor", version: 1}, ...]`）
3. 成功 → versioned capability negotiation
4. `CAPS_V2` 不存在 → fallback 到 `CAP v1` bitmask

## 理由

- 符合 spec:722 additive-only 原則（不改既有 UUID 語意 = 不做 breaking change）
- CAP v1 已在韌體合約成形（ble_api:537），改語意會斷掉舊韌體/工具/測試
- 大廠做法一致（SmartThings capability versioning、Cisco Meraki API versioning、Azure DTDL v2/v3 並存）

## 護欄

- CAP v1 角色寫死為 **bootstrap/fallback only**，不讓它和 CAPS_V2 長期並列成兩套主邏輯

## 影響範圍

capability negotiation、tab 顯示、version compatibility、graceful degradation
