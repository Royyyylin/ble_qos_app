# App 必負責範圍

[← 回 app-scope.md](../app-scope.md)

---

## 1. UI / UX Presentation

App 必須負責：

- GW / ED 資訊頁面呈現（Scanner、Dashboard、Roster、HA、Control、Admin）
- per-ED QoS metrics 可視化（RSSI, PDR, Latency, Jitter, PHY, TX, Throughput）
- online / registered / empty / degraded / orphaned 等狀態的畫面表達
- failover / switchover / disconnected / unhealthy 等事件的 UI 呈現
- 按鈕、表單、確認對話框、告警、toast、banner

## 2. User Interaction Flows

App 必須負責：

- rename alias flow（long-press → dialog → local pending → Central sync）
- add/remove device flow（CMD_V2 ROSTER_ADD / ROSTER_REMOVE）
- connect/register flow（CMD_V2 CONNECT_ED）
- manual refresh / retry / reconnect flow
- manual failover / maintenance 操作入口（若權限允許）
- provisioning / pairing / assign / remove 引導

## 3. Local State / Cache

App 必須負責：

- local view-state（頁面切換、filter、sort、selection）
- 暫存未提交的 rename / settings edit
- Central sync snapshot 的本地快取
- 本地 UI 偏好設定
- Persistent DB（schema v3: DeviceIdentities + alias, Devices, Alerts, AuditLog, DeviceTelemetry）

## 4. Role-Aware UI Gating

App 必須負責：

- 依角色顯示或隱藏功能（normal / maintenance / engineer）
- `PermissionGuard.canWrite(role, action)` 決定 UI 元素可見性
- Level 1（normal）：只讀，rename 隱藏
- Level 2（maintenance）：可 rename、CTRL、GW_CFG、cmdReboot、ROSTER ops
- Level 3（engineer）：可 MODE/ROLE、ENG_UNLOCK、PIN management

**App 做的是 UI gating，真正的權限 enforcement 以 Central auth/RBAC 為準。**

## 5. Data Presentation Semantics

App 必須定義與落實：

- 顯示名稱優先序（見 06-alias-qos-role.md）
- QoS 數值格式化（數值 + 單位並排，色彩分級）
- `--` = 無資料（ED registered 但未 online）
- `N/A` = 非活躍模式（Throughput in non-TP mode）
- 韌體回 0 值時保留 last valid（STATUS polling）
- 狀態色：綠=Online/Good, 橘=Stale/Warning, 紅=Error/Weak, 灰=Offline/Unknown

## 6. 與 QoS 專案脈絡對齊

App repo 面向 QoS 專案中的 GW / ED UI 管理與操作：

- Scanner（Fleet Overview）：GW→ED 收合列表 + search + rename
- Roster：per-ED QoS metrics 列表（方案 B）+ Connect/Remove + Discovered EDs
- Dashboard：GW 自身資訊（FW version, uptime, connection summary, GW_CFG）
- HA：Standalone Mode / HA heartbeat + failover history
- Control：QoS profile 選擇 + Device Role write
- Admin：ENG_UNLOCK + CMD Reboot + MODE/ROLE + GW_CFG Editor + PIN Management
- HTML Prototype：`docs/prototype/` 作為 Flutter 遷移 spec

App repo 是 **human-facing interaction owner**，不是 **system-wide metadata source of truth**。
