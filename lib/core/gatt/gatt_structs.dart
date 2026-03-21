import 'dart:typed_data';

/// Binary codecs for firmware GATT structs.
/// Sizes protected by BUILD_ASSERT in firmware — must match exactly.
/// Source of truth: src/qos_service.h

/// qos_status — 13 bytes, STATUS characteristic (0x2A1D)
class QosStatus {
  final int zone;       // uint8: NEAR=0, MID=1, FAR=2, EDGE=3
  final int profile;    // uint8: FAST=0, BALANCED=1, ROBUST=2
  final int phy;        // uint8: 1M=1, 2M=2, CODED_S8=4, CODED_S2=5
  final int txPower;    // int8
  final int rssi;       // int8
  final int pdr;        // uint8 (0-100%)
  final int interval;   // uint16 LE (ms * 1.25)
  final int latency;    // uint16 LE (ms)
  final int jitter;     // uint16 LE (ms)
  final int tp;         // uint8 (B/s scaled)

  const QosStatus({
    required this.zone,
    required this.profile,
    required this.phy,
    required this.txPower,
    required this.rssi,
    required this.pdr,
    required this.interval,
    required this.latency,
    required this.jitter,
    required this.tp,
  });

  static const int size = 13;

  factory QosStatus.fromBytes(Uint8List data) {
    if (data.length != size) {
      throw ArgumentError('QosStatus: expected $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosStatus(
      zone: bd.getUint8(0),
      profile: bd.getUint8(1),
      phy: bd.getUint8(2),
      txPower: bd.getInt8(3),
      rssi: bd.getInt8(4),
      pdr: bd.getUint8(5),
      interval: bd.getUint16(6, Endian.little),
      latency: bd.getUint16(8, Endian.little),
      jitter: bd.getUint16(10, Endian.little),
      tp: bd.getUint8(12),
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
