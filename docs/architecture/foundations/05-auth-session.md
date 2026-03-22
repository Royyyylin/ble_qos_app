# 5. 認證 Session-Based ✅

## 決策

- 角色提升是 session，不是永久 entitlement
- App 被 kill → 重啟後回到「巡視人員」（Normal）
- GW_CFG：Role-1 唯讀，Role-2 可寫（對齊韌體 `engineer_unlock` prerequisite，ble_api:248）
  - 若 Role-1 有現場調整需求，另開 maintenance-safe config surface，不放開整個 GW_CFG
- Engineer timeout = **5 分鐘**（對齊韌體 `QOS_ENG_UNLOCK_TIMEOUT_MS`，ble_api:304）
  - UX guardrail：剩餘 60 秒顯示倒數警示 + Lock now 按鈕 + 危險操作二次確認
- PIN 存 secure storage（iOS Keychain / Android EncryptedSharedPreferences），不存明文
- 本地 PIN 驗證只算便利功能，不算安全邊界

## 原則

先對齊 firmware authority，再談 app UX 細化。

## 護欄

- C2：現場 installer 需求另開 maintenance-safe config backlog，不回頭放寬 GW_CFG
- C3：補明確 UX 規則 — 是否顯示倒數、剩 60 秒警示、Lock now 按鈕、哪些操作延長 session
