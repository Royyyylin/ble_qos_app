# 3. BLE Lifecycle ⏳（待 #2 stable ID 定案）

**決策方向**：visible scan + task-scoped connection + explicit background restore

```
Scanner 頁面（前景）→ filtered scan
  │ 選擇裝置 → 停掃
  ▼
Device Session（前景）→ 單台 active 連線 + PING keepalive
  │ 離開頁面 / App 背景化
  ▼
背景 → 停掃、斷線或顯式 OS 背景機制（不靠全局常駐掃描）
  │ 回到前景
  ▼
恢復 → 重新檢查狀態 + 重建 session
```

## 大廠做法

- **Apple**：scan only when you need to → 找到就 stopScan → 背景靠 state restoration，不假設 app 永遠活著
- **Android**：不鼓勵 periodic scans → 背景用 PendingIntent scan 或 companion APIs → 長時間連線用 foreground service

## 規則

- **不做**：全 App 常駐掃描、2s/3s duty scan 撐全局
- **掃描**：只在 Scanner 前景頁，選到裝置即停，離頁即停
- **連線**：同一時間只連一台裝置
- **背景**：必要時用 OS 原生背景 BLE 機制，不自己撐
- **恢復**：回前景視為可能中斷，重新檢查狀態

## 待定細節

- [ ] 背景恢復具體用哪個 OS 機制？（iOS state restoration / Android companion device?）
- [ ] scan 停止後 scan results 保留多久？（TTL?）
- [ ] session 斷線後重連 flow 的狀態機定義
