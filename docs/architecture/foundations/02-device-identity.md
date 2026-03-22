# 2. 裝置 Identity ⏳

**問題**：iOS 不暴露 BLE MAC address，Android 也不應把 MAC 當 domain identity。

## 決策方向（待細部設計）

Identity hierarchy：
```
device_identity     ← 產品主身份（DB 主鍵、路由 ID、跨 session 穩定）
  provisioning_id   ← 次要穩定身份（安裝時寫入）
    transport_id    ← 平台 BLE 連線身份（iOS: CBPeripheral.identifier / Android: MAC）
      MAC/address   ← 僅 metadata，不進主模型
```

## 大廠做法

- **Apple**：`CBPeripheral.identifier`（系統 UUID）取回已知裝置；BLE random address 會變，不當長期身份
- **Cisco Meraki**：inventory 以 serial / cloud ID / org / network assignment 管理；MAC 可查但非主鍵
- **SmartThings**：device profile / capability id / component id，不用 transport address 當 domain model

## 待定細節

- [ ] `device_identity` 怎麼生成？（App 端 UUID? 韌體端 serial? provisioning 寫入?）
- [ ] 韌體是否需要新增 DEVICE_IDENTITY characteristic？或用現有 DEVICE_INFO?
- [ ] scan result model 怎麼從 MAC-based 改成 identity-based?
- [ ] GoRouter `/device/:id` 改用什麼 ID?
- [ ] DB `devices` 表主鍵改成什麼?

## 影響範圍

路由、DB schema、scan result model、所有 device reference
