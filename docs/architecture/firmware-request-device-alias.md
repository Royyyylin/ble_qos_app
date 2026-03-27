# Firmware Request: DEVICE_ALIAS Characteristic

**Date:** 2026-03-26
**Requester:** App team
**Priority:** Normal

## Summary

App 需要一個可讀寫的 GATT characteristic 讓技術員為裝置設定別名（如「3F-會議室-GW」）。別名存在裝置 NVS，任何手機連上都能讀到同一個名字。

## Specification

```yaml
- name: DEVICE_ALIAS
  uuid: "6f8a9c22-2c1a-4b6f-8a11-8ddc1f4e7b25"
  properties: [read, write]
  data_type: UTF-8 string
  size_bytes: 0-20
  description: User-assigned device alias, NVS persistent
  write_authority: phone_only
  storage: NVS key "qos/alias"
  default: "" (empty string)
```

## Behavior

| Operation | 說明 |
|-----------|------|
| **Read** | 回傳 NVS 中的 alias。若從未設定，回傳空字串 (0 bytes)。 |
| **Write** | 將 UTF-8 字串存入 NVS。寫入空字串 = 清除 alias。 |
| **Boot** | 從 NVS 載入 alias。NVS key 不存在時 = 空字串。 |

## Notes

- UUID `0x22` 是目前最後一個 vendor UUID (`capsV2 = 0x21`) 的下一個
- 廣播名不需要改變 — App 透過 GATT read 取得 alias
- 權限控制由 App 端處理（maintenance+ 才能觸發 write），韌體端不需要額外鎖
- 需要更新 `ble_api.yaml`
