import 'dart:typed_data';

/// Binary codecs for firmware GATT structs.
/// Sizes protected by BUILD_ASSERT in firmware — must match exactly.
/// Source of truth: src/qos_service.h + ble_api.yaml

/// fw_version_wire — 6 bytes, FW_VERSION characteristic (6f8a9c1b).
class FwVersion {
  final int major;
  final int minor;
  final int patch;
  final int buildNum;

  const FwVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.buildNum,
  });

  static const int size = 6;

  String get label => '$major.$minor.$patch+$buildNum';

  factory FwVersion.fromBytes(Uint8List data) {
    if (data.length < size) {
      throw ArgumentError('FwVersion: expected >= $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return FwVersion(
      major: bd.getUint8(0),
      minor: bd.getUint8(1),
      patch: bd.getUint8(2),
      buildNum: bd.getUint16(3, Endian.little),
    );
  }
}

/// device_info_wire — 8 bytes, DEVICE_INFO characteristic (6f8a9c1c).
class DeviceInfoGatt {
  final int uptimeSeconds;
  final int resetCount;
  final int hwRev;
  final int role;

  const DeviceInfoGatt({
    required this.uptimeSeconds,
    required this.resetCount,
    required this.hwRev,
    required this.role,
  });

  static const int size = 8;

  String get uptimeLabel {
    final h = uptimeSeconds ~/ 3600;
    final m = (uptimeSeconds % 3600) ~/ 60;
    final s = uptimeSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String get roleLabel => switch (role) {
    0 => 'Unprovisioned',
    1 => 'End Device',
    2 => 'Gateway',
    3 => 'Repeater',
    4 => 'CC',
    _ => 'Unknown ($role)',
  };

  factory DeviceInfoGatt.fromBytes(Uint8List data) {
    if (data.length < size) {
      throw ArgumentError('DeviceInfoGatt: expected >= $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return DeviceInfoGatt(
      uptimeSeconds: bd.getUint32(0, Endian.little),
      resetCount: bd.getUint16(4, Endian.little),
      hwRev: bd.getUint8(6),
      role: bd.getUint8(7),
    );
  }
}

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
/// Layout (firmware qos_service.h):
///   pdr_x100(u16LE), lat_ms(u16LE), jit_ms(u16LE), rssi(int8),
///   prof(u8), phy(u8), tx_power(int8), tp_Bps(u16LE), tp_peak_Bps(u16LE),
///   enomem_cnt(u16LE), eagain_cnt(u16LE), min_stack_free(u16LE)
class QosMetricsV2 {
  final int pdr;          // 0-100 (%)
  final int latency;      // ms
  final int jitter;       // ms
  final int rssi;         // dBm
  final int profile;      // FAST=0, BALANCED=1, ROBUST=2
  final int phy;          // 1M=1, 2M=2, CODED_S8=4
  final int txPower;      // dBm
  final int tpBps;        // throughput bytes/sec
  final int tpPeakBps;    // peak throughput bytes/sec
  final int enomemCnt;    // notify ENOMEM counter
  final int eagainCnt;    // notify EAGAIN counter
  final int minStackFree; // min free stack bytes

  const QosMetricsV2({
    this.pdr = 0,
    this.latency = 0,
    this.jitter = 0,
    this.rssi = 0,
    this.profile = 0,
    this.phy = 0,
    this.txPower = 0,
    this.tpBps = 0,
    this.tpPeakBps = 0,
    this.enomemCnt = 0,
    this.eagainCnt = 0,
    this.minStackFree = 0,
  });

  static const int size = 20;

  factory QosMetricsV2.fromBytes(Uint8List data) {
    if (data.length < size) {
      throw ArgumentError('QosMetricsV2: expected >= $size bytes, got ${data.length}');
    }
    final bd = ByteData.sublistView(data);
    return QosMetricsV2(
      pdr: (bd.getUint16(0, Endian.little) / 100).round(),
      latency: bd.getUint16(2, Endian.little),
      jitter: bd.getUint16(4, Endian.little),
      rssi: bd.getInt8(6),
      profile: bd.getUint8(7),
      phy: bd.getUint8(8),
      txPower: bd.getInt8(9),
      tpBps: bd.getUint16(10, Endian.little),
      tpPeakBps: bd.getUint16(12, Endian.little),
      enomemCnt: bd.getUint16(14, Endian.little),
      eagainCnt: bd.getUint16(16, Endian.little),
      minStackFree: bd.getUint16(18, Endian.little),
    );
  }
}

/// qos_ctrl — 9 bytes, CTRL characteristic (0x2A21)
/// Layout per ble_api.yaml: profile(0) phy(1) tx_power(2) tp_mode(3)
///   credit_alarm(4) credit_ctrl(5) credit_rs485(6) interval(7-8 u16LE)
class QosCtrl {
  final int profile;      // uint8, offset 0
  final int phy;          // uint8, offset 1
  final int txPower;      // int8, offset 2
  final int tpMode;       // uint8, offset 3 (0=STRESS, 1=PRODUCT)
  final int creditAlarm;  // uint8, offset 4
  final int creditCtrl;   // uint8, offset 5
  final int creditRs485;  // uint8, offset 6
  final int interval;     // uint16 LE, offset 7

  const QosCtrl({
    required this.profile,
    required this.phy,
    required this.txPower,
    this.tpMode = 1,
    required this.creditAlarm,
    required this.creditCtrl,
    required this.creditRs485,
    required this.interval,
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
      tpMode: bd.getUint8(3),
      creditAlarm: bd.getUint8(4),
      creditCtrl: bd.getUint8(5),
      creditRs485: bd.getUint8(6),
      interval: bd.getUint16(7, Endian.little),
    );
  }

  /// Serialize to 9-byte payload per ble_api.yaml wire_format.
  Uint8List toBytes() {
    final data = Uint8List(size);
    final bd = ByteData.sublistView(data);
    bd.setUint8(0, profile);
    bd.setUint8(1, phy);
    bd.setInt8(2, txPower);
    bd.setUint8(3, tpMode);
    bd.setUint8(4, creditAlarm);
    bd.setUint8(5, creditCtrl);
    bd.setUint8(6, creditRs485);
    bd.setUint16(7, interval, Endian.little);
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
  final int seq;     // uint8, offset 4 (per-type drop detection)

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
      seq: bd.getUint8(4),
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
    // BLE address is little-endian on wire: AA:BB:CC:DD:EE:FF → [FF,EE,DD,CC,BB,AA]
    for (int i = 0; i < 6; i++) {
      data[2 + (5 - i)] = int.parse(parts[i], radix: 16);
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
    // BLE address stored little-endian: read in reverse for display format
    final addr = List.generate(6, (i) =>
        data[offset + 2 + (5 - i)].toRadixString(16).padLeft(2, '0').toUpperCase(),
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

/// CMD_V2 opcodes — transaction-based command (vendor 6f8a9c1f).
class CmdV2Opcode {
  CmdV2Opcode._();
  static const int reboot = 0x01;
  static const int setMaxEd = 0x02;
  static const int connectEd = 0x03;
  static const int disconnectEd = 0x04;
  static const int rosterAdd = 0x05;
  static const int rosterRemove = 0x06;
}

/// CMD_V2 builder — transaction-based command (vendor 6f8a9c1f).
/// Wire: txn_id(u8) + opcode(u8) + payload(0-7 bytes).
class CmdV2 {
  CmdV2._();

  /// Build a CMD_V2 payload.
  static Uint8List build(int txnId, int opcode, [Uint8List? payload]) {
    assert(txnId >= 1 && txnId <= 255, 'txn_id must be 1-255');
    final pLen = payload?.length ?? 0;
    final data = Uint8List(2 + pLen);
    data[0] = txnId;
    data[1] = opcode;
    if (payload != null) data.setRange(2, 2 + pLen, payload);
    return data;
  }

  /// CMD 0x05 ROSTER_ADD: [addr_type, addr[6]] = 7 bytes payload.
  static Uint8List rosterAdd(int txnId, String macAddress, {int addrType = 1}) {
    final parts = macAddress.split(':');
    if (parts.length != 6) {
      throw ArgumentError('Invalid MAC address: $macAddress');
    }
    final payload = Uint8List(7);
    payload[0] = addrType;
    for (int i = 0; i < 6; i++) {
      payload[1 + (5 - i)] = int.parse(parts[i], radix: 16);
    }
    return build(txnId, CmdV2Opcode.rosterAdd, payload);
  }

  /// CMD 0x06 ROSTER_REMOVE: [logical_slot] = 1 byte payload.
  static Uint8List rosterRemove(int txnId, int logicalSlot) {
    return build(txnId, CmdV2Opcode.rosterRemove, Uint8List.fromList([logicalSlot]));
  }

  /// CMD 0x03 CONNECT_ED: [addr_type, addr[6]] = 7 bytes payload.
  static Uint8List connectEd(int txnId, String macAddress, {int addrType = 1}) {
    final parts = macAddress.split(':');
    if (parts.length != 6) {
      throw ArgumentError('Invalid MAC address: $macAddress');
    }
    final payload = Uint8List(7);
    payload[0] = addrType;
    for (int i = 0; i < 6; i++) {
      payload[1 + (5 - i)] = int.parse(parts[i], radix: 16);
    }
    return build(txnId, CmdV2Opcode.connectEd, payload);
  }

  /// CMD 0x04 DISCONNECT_ED: [ed_idx] = 1 byte payload.
  static Uint8List disconnectEd(int txnId, int edIndex) {
    return build(txnId, CmdV2Opcode.disconnectEd, Uint8List.fromList([edIndex]));
  }
}

/// CMD_RESULT status codes.
class CmdResultStatus {
  CmdResultStatus._();
  static const int success = 0;
  static const int error = 1;
  static const int inProgress = 2;
  static const int rejected = 3;
}

/// qos_cmd_result — 6 bytes, CMD_RESULT characteristic (vendor 6f8a9c1e).
/// Subscribe for async command responses from CMD_V2.
class CmdResult {
  final int txnId;    // echoed from CMD_V2
  final int opcode;
  final int status;   // CmdResultStatus.*
  final int v0;       // opcode-specific
  final int v1;       // opcode-specific

  const CmdResult({
    required this.txnId,
    required this.opcode,
    required this.status,
    this.v0 = 0,
    this.v1 = 0,
  });

  static const int size = 6;

  bool get isSuccess => status == CmdResultStatus.success;
  bool get isError => status == CmdResultStatus.error;

  factory CmdResult.fromBytes(Uint8List data) {
    if (data.length < size) {
      throw ArgumentError('CmdResult: expected >= $size bytes, got ${data.length}');
    }
    return CmdResult(
      txnId: data[0],
      opcode: data[1],
      status: data[2],
      v0: data[3],
      v1: data[4],
    );
  }
}

/// Roster slot state values (ROSTER_LIST characteristic).
class RosterSlotState {
  RosterSlotState._();
  static const int empty = 0;
  static const int registered = 1;
  static const int online = 2;
}

/// qos_roster_list_entry — 9 bytes per slot, ROSTER_LIST characteristic (6f8a9c20).
/// Layout: logical_slot(u8) + addr_type(u8) + addr[6] + state(u8).
class RosterEntry {
  final int logicalSlot;
  final int addrType;
  final String address; // "AA:BB:CC:DD:EE:FF"
  final int state;      // RosterSlotState.*

  const RosterEntry({
    required this.logicalSlot,
    required this.addrType,
    required this.address,
    required this.state,
  });

  static const int entrySize = 9;

  bool get isEmpty => state == RosterSlotState.empty;
  bool get isRegistered => state == RosterSlotState.registered;
  bool get isOnline => state == RosterSlotState.online;

  String get stateLabel => switch (state) {
    RosterSlotState.empty => 'Empty',
    RosterSlotState.registered => 'Registered',
    RosterSlotState.online => 'Online',
    _ => 'Unknown ($state)',
  };

  factory RosterEntry.fromBytes(Uint8List data, [int offset = 0]) {
    final slot = data[offset];
    final aType = data[offset + 1];
    final addr = List.generate(6, (i) =>
        data[offset + 2 + (5 - i)].toRadixString(16).padLeft(2, '0').toUpperCase(),
    ).join(':');
    final st = data[offset + 8];
    return RosterEntry(
      logicalSlot: slot,
      addrType: aType,
      address: addr,
      state: st,
    );
  }

  /// Parse full ROSTER_LIST payload (N × 9 bytes). Includes all slots (even empty).
  static List<RosterEntry> parseList(Uint8List data) {
    final entries = <RosterEntry>[];
    for (int i = 0; i + entrySize <= data.length; i += entrySize) {
      entries.add(RosterEntry.fromBytes(data, i));
    }
    return entries;
  }
}

/// ha_heartbeat — 21 bytes, HA_HB characteristic (vendor 6f8a9c17)
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
