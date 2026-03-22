/// Tooltip content for all metrics and controls.
/// Source: UI_REDESIGN_SPEC.md §Tooltip Content
class TooltipContent {
  TooltipContent._();

  static const rssi = (
    title: 'RSSI 信號強度',
    body: '> -65 dBm 強信號（綠）\n-65 ~ -85 中等（橘）\n< -85 弱信號（紅）',
  );

  static const pdr = (
    title: 'PDR 封包送達率',
    body: '> 95% 良好（綠）\n85~95% 注意（橘）\n< 85% 差（紅）',
  );

  static const latency = (
    title: '延遲 Latency',
    body: '< 20ms 低延遲（綠）\n20~50ms 正常（橘）\n> 50ms 高延遲（紅）',
  );

  static const jitter = (
    title: '延遲抖動 Jitter',
    body: '< 5ms 穩定（綠）\n5~15ms 波動（橘）\n> 15ms 不穩定（紅）',
  );

  static const phy = (
    title: 'PHY 無線電模式',
    body: '2M — 最快，距離最短\n1M — 平衡\nCoded S2 — 500kbps，較遠\nCoded S8 — 125kbps，最遠',
  );

  static const txPower = (
    title: 'TX Power 發射功率',
    body: '範圍 -40 ~ +8 dBm\n值越高距離越遠但越耗電',
  );

  static const profile = (
    title: 'Profile QoS 策略',
    body: 'FAST — 2M / 15ms，低延遲\nBALANCED — 1M / 30ms，平衡\nROBUST — Coded / 50ms，高可靠',
  );

  static const mode = (
    title: 'Mode 模式',
    body: 'AUTO — 韌體自動調整 QoS 參數\nENGINEER — 手動控制，5 分鐘 timeout',
  );
}
