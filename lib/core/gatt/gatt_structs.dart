import 'dart:typed_data';

/// Binary codecs for firmware GATT structs.
/// Sizes protected by BUILD_ASSERT in firmware — must match exactly.
/// Source of truth: src/qos_service.h

/// qos_status — 13 bytes full / 4 bytes indexed, STATUS characteristic (0x2A1D)
///
/// Full format (13 bytes, from GATT read or legacy notify):
///   rssi(int8), pdr_x100(u16LE), lat_ms(u16LE), jit_ms(u16LE),
///   profile(u8), phy(u8), tx_power(int8), connected(u8), interval(u16LE)
///
/// Indexed format (4 bytes, from GW multi-ED notify):
///   ed_idx(u8), flags(u8), tx_power(int8), interval_low(u8)
///   flags: [connected:1][zone:2][profile:2][phy_enc:2][reserved:1]
class QosStatus {
  final int zone;       // NEAR=0, MID=1, FAR=2, EDGE=3
  final int profile;    // FAST=0, BALANCED=1, ROBUST=2
  final int phy;        // 1M=1, 2M=2, CODED_S8=4
  final int txPower;    // dBm
  final int rssi;       // dBm
  final int pdr;        // 0-100 (%)
  final int interval;   // 1.25ms units
  final int latency;    // ms
  final int jitter;     // ms
  final int tp;         // B/s scaled
  final int edIndex;    // ED index (from indexed format)

  const QosStatus({
    this.zone = 0,
    this.profile = 0,
    this.phy = 0,
    this.txPower = 0,
    this.rssi = 0,
    this.pdr = 0,
    this.interval = 0,
    this.latency = 0,
    this.jitter = 0,
    this.tp = 0,
    this.edIndex = 0,
  });

  /// Full STATUS struct size (GATT read).
  static const int size = 13;

  /// Indexed STATUS size (GW multi-ED notify).
  static const int indexedSize = 4;

  /// Parse from either 13-byte full or 4-byte indexed format.
  /// Auto-detects format by data length.
  static QosStatus parse(Uint8List data) {
    if (data.length >= size) {
      return QosStatus.fromBytes(data);
    } else if (data.length >= indexedSize) {
      return QosStatus.fromIndexedBytes(data);
    }
    throw ArgumentError('QosStatus: expected >= $indexedSize bytes, got ${data.length}');
  }

  /// Parse full 13-byte STATUS struct (firmware qos_service.h layout).
  factory QosStatus.fromBytes(Uint8List data) {
    if (data.length < size) {
      throw ArgumentError('QosStatus: expected >= $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosStatus(
      rssi: bd.getInt8(0),
      pdr: (bd.getUint16(1, Endian.little) / 100).round(), // pdr_x100 → %
      latency: bd.getUint16(3, Endian.little),
      jitter: bd.getUint16(5, Endian.little),
      profile: bd.getUint8(7),
      phy: bd.getUint8(8),
      txPower: bd.getInt8(9),
      // connected at offset 10 — not exposed in UI
      interval: bd.getUint16(11, Endian.little),
    );
  }

  /// Parse 4-byte indexed STATUS (GW multi-ED compact notify).
  factory QosStatus.fromIndexedBytes(Uint8List data) {
    if (data.length < indexedSize) {
      throw ArgumentError('QosStatus indexed: expected >= $indexedSize bytes, got ${data.length}');
    }
    final edIdx = data[0];
    final flags = data[1];
    final txPower = data[2].toSigned(8); // int8
    final intervalLow = data[3];

    // Decode flags: [connected:1][zone:2][profile:2][phy_enc:2][reserved:1]
    final zone = (flags >> 1) & 0x03;
    final profile = (flags >> 3) & 0x03;
    final phyEnc = (flags >> 5) & 0x03;
    // Decode phy: 0=1M, 1=2M, 2=S8
    final phy = switch (phyEnc) { 1 => 2, 2 => 4, _ => 1 };

    return QosStatus(
      edIndex: edIdx,
      zone: zone,
      profile: profile,
      phy: phy,
      txPower: txPower,
      interval: intervalLow,
    );
  }
}

/// qos_metrics_v2 — 20 bytes, METRICS characteristic (0x2A23)
class QosMetricsV2 {
  final Uint8List raw;

  const QosMetricsV2(this.raw);

  static const int size = 20;

  factory QosMetricsV2.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosMetricsV2: expected $size bytes, got ${data.length}');
    }
    return QosMetricsV2(Uint8List.fromList(data));
  }
}

/// qos_ctrl — 9 bytes, CTRL characteristic (0x2A21)
class QosCtrl {
  final int profile;      // uint8
  final int phy;          // uint8
  final int txPower;      // int8
  final int interval;     // uint16 LE
  final int creditAlarm;  // uint8
  final int creditCtrl;   // uint8
  final int creditRs485;  // uint8
  final int flags;        // uint8

  const QosCtrl({
    required this.profile,
    required this.phy,
    required this.txPower,
    required this.interval,
    required this.creditAlarm,
    required this.creditCtrl,
    required this.creditRs485,
    required this.flags,
  });

  static const int size = 9;

  factory QosCtrl.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosCtrl: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosCtrl(
      profile: bd.getUint8(0),
      phy: bd.getUint8(1),
      txPower: bd.getInt8(2),
      interval: bd.getUint16(3, Endian.little),
      creditAlarm: bd.getUint8(5),
      creditCtrl: bd.getUint8(6),
      creditRs485: bd.getUint8(7),
      flags: bd.getUint8(8),
    );
  }

  /// Serialize to 9-byte payload for CTRL characteristic write.
  /// Byte layout mirrors fromBytes() field order exactly.
  Uint8List toBytes() {
    final data = Uint8List(size);
    final bd = ByteData.sublistView(data);
    bd.setUint8(0, profile);
    bd.setUint8(1, phy);
    bd.setInt8(2, txPower);
    bd.setUint16(3, interval, Endian.little);
    bd.setUint8(5, creditAlarm);
    bd.setUint8(6, creditCtrl);
    bd.setUint8(7, creditRs485);
    bd.setUint8(8, flags);
    return data;
  }
}

/// qos_gw_cfg_v2 — 8 bytes, GW_CFG characteristic (0x2A25)
class QosGwCfgV2 {
  final int ver;
  final int tpMode;
  final int log;
  final int flags;
  final int creditAlarm;
  final int creditCtrl;
  final int creditRs485;
  final int reserved;

  const QosGwCfgV2({
    required this.ver,
    required this.tpMode,
    required this.log,
    required this.flags,
    required this.creditAlarm,
    required this.creditCtrl,
    required this.creditRs485,
    required this.reserved,
  });

  static const int size = 8;

  factory QosGwCfgV2.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosGwCfgV2: expected $size bytes, got ${data.length}');
    }
    return QosGwCfgV2(
      ver: data[0],
      tpMode: data[1],
      log: data[2],
      flags: data[3],
      creditAlarm: data[4],
      creditCtrl: data[5],
      creditRs485: data[6],
      reserved: data[7],
    );
  }

  Uint8List toBytes() {
    return Uint8List.fromList([
      ver, tpMode, log, flags,
      creditAlarm, creditCtrl, creditRs485, reserved,
    ]);
  }
}

/// qos_evt_v1 — 6 bytes, EVT characteristic (vendor 6f8a9c13)
class QosEvtV1 {
  final int type;    // 0xE1 = ALARM, 0xE2 = INFO
  final int id;
  final int v0;
  final int v1;
  final int seq;     // uint16 LE

  const QosEvtV1({
    required this.type,
    required this.id,
    required this.v0,
    required this.v1,
    required this.seq,
  });

  static const int size = 6;
  static const int typeAlarm = 0xE1;
  static const int typeInfo = 0xE2;

  bool get isAlarm => type == typeAlarm;

  factory QosEvtV1.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosEvtV1: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosEvtV1(
      type: bd.getUint8(0),
      id: bd.getUint8(1),
      v0: bd.getUint8(2),
      v1: bd.getUint8(3),
      seq: bd.getUint16(4, Endian.little),
    );
  }
}

/// qos_ping_rsp — 8 bytes, PING notify response (0x2A24)
class QosPingRsp {
  final int echoTs;   // uint32 LE — original timestamp echoed back
  final int rttUs;    // uint32 LE — round-trip time in microseconds

  const QosPingRsp({required this.echoTs, required this.rttUs});

  static const int size = 8;

  factory QosPingRsp.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosPingRsp: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosPingRsp(
      echoTs: bd.getUint32(0, Endian.little),
      rttUs: bd.getUint32(4, Endian.little),
    );
  }
}

/// CMD opcodes for the CMD characteristic (0x2A20).
class CmdCode {
  CmdCode._();
  static const int reboot = 0x01;
  static const int setMaxEd = 0x02;
  static const int connectEd = 0x03;
  static const int disconnectEd = 0x04;

  /// Build CMD 0x03 payload: [0x03, addr_type, addr[6]] = 8 bytes.
  /// [macAddress] format: "AA:BB:CC:DD:EE:FF"
  /// [addrType] 0=public, 1=random (default random for nRF)
  static Uint8List buildConnectEdPayload(String macAddress, {int addrType = 1}) {
    final parts = macAddress.split(':');
    if (parts.length != 6) {
      throw ArgumentError('Invalid MAC address: $macAddress');
    }
    final data = Uint8List(8);
    data[0] = connectEd;
    data[1] = addrType;
    for (int i = 0; i < 6; i++) {
      data[2 + i] = int.parse(parts[i], radix: 16);
    }
    return data;
  }

  /// Build CMD 0x04 payload: [0x04, ed_idx] = 2 bytes.
  static Uint8List buildDisconnectEdPayload(int edIndex) {
    return Uint8List.fromList([disconnectEd, edIndex]);
  }
}

/// EVT INFO IDs for CMD responses (from EVT characteristic notify).
class EvtInfoId {
  EvtInfoId._();
  static const int cmdConnectOk = 0x20;
  static const int cmdConnectFail = 0x21;
  static const int cmdDisconnectOk = 0x22;
  static const int cmdDisconnectFail = 0x23;
}

/// ED_LIST entry — 9 bytes per ED slot, from ED_LIST characteristic (6f8a9c1a).
/// Layout: ed_idx(1) + addr_type(1) + addr[6] + connected(1)
class EdListEntry {
  final int edIndex;
  final int addrType;
  final String address; // "AA:BB:CC:DD:EE:FF"
  final bool connected;

  const EdListEntry({
    required this.edIndex,
    required this.addrType,
    required this.address,
    required this.connected,
  });

  static const int entrySize = 9;

  /// Parse a single 9-byte entry.
  factory EdListEntry.fromBytes(Uint8List data, [int offset = 0]) {
    final idx = data[offset];
    final aType = data[offset + 1];
    final addr = List.generate(6, (i) =>
        data[offset + 2 + i].toRadixString(16).padLeft(2, '0').toUpperCase(),
    ).join(':');
    final conn = data[offset + 8] != 0;
    return EdListEntry(
      edIndex: idx,
      addrType: aType,
      address: addr,
      connected: conn,
    );
  }

  /// Parse full ED_LIST payload (N × 9 bytes).
  static List<EdListEntry> parseList(Uint8List data) {
    final entries = <EdListEntry>[];
    for (int i = 0; i + entrySize <= data.length; i += entrySize) {
      final entry = EdListEntry.fromBytes(data, i);
      if (entry.connected) entries.add(entry);
    }
    return entries;
  }
}

/// ha_heartbeat — 21 bytes, HA_HB characteristic (vendor 6f8a9c15)
/// Layout: haRole(1) + epoch(4LE) + heartbeatCount(4LE) + peerStatus(1)
///       + lastFailoverTimestamp(4LE) + lastFailoverReason(1) + reserved(6)
class HaHeartbeat {
  final int haRole;                 // uint8: 0x01=active, 0x02=standby
  final int epoch;                  // uint32 LE — HA cluster generation
  final int heartbeatCount;         // uint32 LE
  final int peerStatus;             // uint8: peer's role
  final int lastFailoverTimestamp;  // uint32 LE — unix epoch
  final int lastFailoverReason;     // uint8

  const HaHeartbeat({
    required this.haRole,
    required this.epoch,
    required this.heartbeatCount,
    required this.peerStatus,
    required this.lastFailoverTimestamp,
    required this.lastFailoverReason,
  });

  static const int size = 21;
  static const int roleActive = 0x01;
  static const int roleStandby = 0x02;

  String get haRoleLabel => switch (haRole) {
    roleActive => 'Active',
    roleStandby => 'Standby',
    _ => 'Unknown (0x${haRole.toRadixString(16)})',
  };

  String get peerStatusLabel => switch (peerStatus) {
    roleActive => 'Active',
    roleStandby => 'Standby',
    _ => 'Unknown (0x${peerStatus.toRadixString(16)})',
  };

  factory HaHeartbeat.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('HaHeartbeat: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return HaHeartbeat(
      haRole: bd.getUint8(0),
      epoch: bd.getUint32(1, Endian.little),
      heartbeatCount: bd.getUint32(5, Endian.little),
      peerStatus: bd.getUint8(9),
      lastFailoverTimestamp: bd.getUint32(10, Endian.little),
      lastFailoverReason: bd.getUint8(14),
    );
  }
}
