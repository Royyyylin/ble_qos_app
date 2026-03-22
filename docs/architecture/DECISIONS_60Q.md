# 60 題架構決策逐題記錄

> 本文件記錄 App 架構 60 個問題的逐題短答。
> 口徑：現況 + 建議決策，不是把 spec 當成已實作事實。
> 日期：2026-03-22
> 配合 `APP_ARCHITECTURE.md` 的 6 項基石一起閱讀。

---

## A. 產品定位

| # | 問題 | 決策 |
|---|------|------|
| 1 | 最終使用者 | 現場工程師 / 安裝人員 / 維運巡檢，不是 consumer |
| 2 | 裝置管理規模 | 多裝置掃描 + 多裝置列表 + 單一 active 連線 |
| 3 | 多手機同時連同一 GW | 不做；v1 明確定成單手機控制 |
| 4 | 上架 Store | PoC 先內部分發；若現場部署與持續更新，最終上架 |
| 5 | iOS | 建議做；spec 已跨平台，iOS BLE 限制會逼設計更穩 |

## B. BLE 連線層

| # | 問題 | 決策 |
|---|------|------|
| 6 | 同時連多台 | v1 不做，但狀態模型保留未來多 session 擴充空間 |
| 7 | 重連策略 | 3-5 次 exponential backoff 後停止，轉手動 Retry |
| 8 | PING 20s 保活 | 可當前景 keepalive，不能當保活保證；被斷線要能正常恢復 |
| 9 | 連線 timeout | connect → discover → PEER_ROLE → capability read 每步都要 timeout |
| 10 | 掃描時機 | 只在 Scanner 前景頁；點到裝置後停掃，離頁/背景停掃 |

## C. GATT 協議層

| # | 問題 | 決策 |
|---|------|------|
| 11 | parser 來源 | 不靠手寫 byte offset；應從 `ble_api.yaml` 生成 parser/fixture/test |
| 12 | CMD timeout | CMD 0x03/0x04 等 EVT 必須有 timeout；不能無限等待 |
| 13 | CMD_V2 準備 | 現在就做 transaction-aware 命令層，為 request/response 預留封裝 |
| 14 | QosStatus 判斷 | 靠長度判斷只適合過渡；長期加明確 version/type |

## D. 狀態管理（Riverpod）

| # | 問題 | 決策 |
|---|------|------|
| 15 | BleConnector 角色 | 可保留為 BLE wrapper，但不該是核心 singleton 狀態源 |
| 16 | scanResults 生命週期 | 要有 TTL/eviction；離開 Scanner 應清理或降級成 cache |
| 17 | edRoster 合併策略 | 先在 repository/reducer 合併 scan 與 GW notify，再對 UI 暴露 |
| 18 | metrics/device 生命週期 | 跟 connection session 走；斷線後標 stale 或清空 |
| 19 | 依賴方向 | scan → session → telemetry/persistence → UI，單向不循環 |

## E. 資料層（Drift DB）

| # | 問題 | 決策 |
|---|------|------|
| 20 | schema migration | 不停在 version 1；加欄位走 additive migration |
| 21 | retention 閾值 | 不寫死；至少做成 app config |
| 22 | telemetry 寫入頻率 | 若每秒寫入 DB 會長很快；只持久化降採樣資料 |
| 23 | DB 類型 | 產品化用 persistent SQLite，不長期用 in-memory |
| 24 | audit log 範圍 | 記錄：解鎖、角色提升、CTRL/GW_CFG/ROLE/CMD、重連與失敗操作 |

## F. 認證與權限

| # | 問題 | 決策 |
|---|------|------|
| 25 | 三角色差異 | Role-0 只讀監控；Role-1 安裝/維護；Role-2 危險控制/診斷 |
| 26 | PIN 驗證方式 | Maintenance PIN 偏 App 本地；Engineer PIN 走韌體 ENG_UNLOCK |
| 27 | PIN 儲存 | 不寫死 code；可配置 + secure storage |
| 28 | Kill app 後角色 | 回到 Normal（較安全且合理的預設） |

## G. Capability 系統

| # | 問題 | 決策 |
|---|------|------|
| 29 | CAP 格式 | ⚠️ 現有衝突：spec 想 CBOR，韌體 docs 是 1-byte bitmask → **待定案** |
| 30 | capability version 升級 | additive-only；App 不支援時隱藏功能，不拖垮整體 |
| 31 | tab 顯示控制 | 不靠 route 參數；由 capability + role 推導 |

## H. 導航與路由

| # | 問題 | 決策 |
|---|------|------|
| 32 | device route id | 不用 BLE MAC；用平台無關 stable ID |
| 33 | deep link 返回 | 不假設能 pop() 回 Scanner；要有 root fallback |
| 34 | Provisioning 入口 | 必須有明確入口；通常只對 unprovisioned device 顯示 |

## I. UI / UX

| # | 問題 | 決策 |
|---|------|------|
| 35 | metric 0 值顯示 | 不顯示 0 像正常值；顯示「等待資料」 |
| 36 | Roster 資料來源 | 不只靠 scan 匹配；區分「GW 已連線」與「目前有廣播」 |
| 37 | HA tab 無 capability | 不存在就隱藏；條件不足顯示「需雙 GW」 |
| 38 | Apply Profile 回饋 | 寫到哪個 characteristic + in-progress + success/failure |
| 39 | 操作回饋一致性 | Connect/Disconnect/Apply/Role write 統一 loading + 結果提示 |
| 40 | 深色/淺色主題 | v1 只做深色；上架正式版補淺色 |
| 41 | 字體 | bundled font（JetBrains Mono）比 platform monospace 穩 |

## J. 錯誤處理

| # | 問題 | 決策 |
|---|------|------|
| 42 | ConnectionErrorScreen | 分出 permission / BT off / busy / timeout / GATT fail / out of range |
| 43 | GATT write retry | 不盲目 retry；只對 transient error 做有限 retry |
| 44 | 無 BLE 權限 | rationale → 請權限 → 被拒導 Settings 完整流程 |
| 45 | App 背景化 | 視為可能中斷；回前景重新檢查狀態 + 重建 session |

## K. 測試

| # | 問題 | 決策 |
|---|------|------|
| 46 | 現有 141 tests | 主要是韌體端，不是 App；App 需另建 coverage 基線 |
| 47 | Widget test 範圍 | 至少覆蓋 Scanner / Device / Error / Auth / Provisioning |
| 48 | BLE integration test | 獨立成 HIL 套件，不混一般 CI |
| 49 | flutter_blue_plus mock | 包一層 adapter，用 fake/repository double，不直接 mock plugin class |

## L. 效能與電池

| # | 問題 | 決策 |
|---|------|------|
| 50 | 省電 | 非 Scanner 頁面停掃，最直接的手段 |
| 51 | BLE 帶寬 | PING 20s + notify 單連線通常可接受，但要量測不憑感覺 |
| 52 | Dashboard 更新 | 局部狀態更新，不是每個 notify 重建整頁 |

## M. 安全性

| # | 問題 | 決策 |
|---|------|------|
| 53 | BLE 加密 | 若控制有風險，最終要求加密連線/配對；至少明文化安全策略 |
| 54 | PIN 傳輸 | 不應明文；Phase 1 做不到也要標記「非安全邊界」 |
| 55 | audit log 保護 | 不讓一般使用者清除或改寫 |

## N. 部署與版本

| # | 問題 | 決策 |
|---|------|------|
| 56 | 相容矩陣 | 必須有；至少用 FW_VERSION + CAP/version 判斷 |
| 57 | OTA 後 layout 變更 | App 以 version/capability 決定 parser，不盲解 |
| 58 | Crash reporting | 納入正式發版基線；iOS MetricKit / Android 崩潰蒐集 |

## O. 韌體依賴

| # | 問題 | 決策 |
|---|------|------|
| 59 | 合約文件化 | UUID / wire format / auth / write authority / timeout / error code 全部文件化 |
| 60 | codegen from ble_api.yaml | 是，App 應從 ble_api.yaml 生成 parser / validator / fixtures |
