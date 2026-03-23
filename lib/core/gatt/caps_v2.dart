import 'dart:typed_data';
import 'package:cbor/cbor.dart';

/// CAPS_V2 CBOR map — spec ble_api.yaml.
/// CBOR keys: 1=proto_ver, 2=cmd_v2_ops, 3=max_ed, 4=has_ha,
///            5=has_uplink, 6=cap_v1, 7=ha_state
class CapsV2 {
  final int protoVer;
  final List<int> cmdV2Ops;
  final int maxEd;
  final bool hasHa;
  final bool hasUplink;
  final int capV1;
  final int haState; // 0=standalone, 1=active, 2=standby

  const CapsV2({
    this.protoVer = 0,
    this.cmdV2Ops = const [],
    this.maxEd = 0,
    this.hasHa = false,
    this.hasUplink = false,
    this.capV1 = 0,
    this.haState = 0,
  });

  String get haStateLabel => switch (haState) {
    0 => 'Standalone',
    1 => 'Active',
    2 => 'Standby',
    _ => 'Unknown ($haState)',
  };

  factory CapsV2.fromBytes(Uint8List data) {
    try {
      final decoded = cbor.decode(data);
      if (decoded is! CborMap) return const CapsV2();

      final map = <int, CborValue>{};
      for (final entry in decoded.entries) {
        if (entry.key is CborSmallInt) {
          map[(entry.key as CborSmallInt).value] = entry.value;
        }
      }

      return CapsV2(
        protoVer: _intVal(map[1]),
        cmdV2Ops: _intListVal(map[2]),
        maxEd: _intVal(map[3]),
        hasHa: _boolVal(map[4]),
        hasUplink: _boolVal(map[5]),
        capV1: _intVal(map[6]),
        haState: _intVal(map[7]),
      );
    } catch (_) {
      return const CapsV2();
    }
  }

  static int _intVal(CborValue? v) {
    if (v is CborSmallInt) return v.value;
    if (v is CborInt) return v.toInt();
    return 0;
  }

  static bool _boolVal(CborValue? v) {
    if (v is CborBool) return v.value;
    if (v is CborSmallInt) return v.value != 0;
    return false;
  }

  static List<int> _intListVal(CborValue? v) {
    if (v is CborList) {
      return v.map((e) => _intVal(e)).toList();
    }
    return const [];
  }
}
