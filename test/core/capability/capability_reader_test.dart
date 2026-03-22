import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/capability/capability_model.dart';
import 'package:ble_qos_app/core/capability/capability_reader.dart';

void main() {
  group('CapabilityReader', () {
    group('parseCapabilityBytes', () {
      test('given_valid_bytes_when_parsed_then_returns_capability_list', () {
        // Format: [count:1][id_len:1][id:N][version:1]...
        // 1 capability: "qos_monitor" v1
        final idBytes = 'qos_monitor'.codeUnits;
        final bytes = Uint8List.fromList([
          1, // count
          idBytes.length, // id_len
          ...idBytes, // id
          1, // version
        ]);
        final caps = CapabilityReader.parseCapabilityBytes(bytes);
        expect(caps, hasLength(1));
        expect(caps.first.id, 'qos_monitor');
        expect(caps.first.version, 1);
      });

      test('given_multiple_caps_when_parsed_then_returns_all', () {
        final id1 = 'qos_monitor'.codeUnits;
        final id2 = 'ha_runtime'.codeUnits;
        final bytes = Uint8List.fromList([
          2, // count
          id1.length, ...id1, 1, // qos_monitor v1
          id2.length, ...id2, 2, // ha_runtime v2
        ]);
        final caps = CapabilityReader.parseCapabilityBytes(bytes);
        expect(caps, hasLength(2));
        expect(caps[0].id, 'qos_monitor');
        expect(caps[0].version, 1);
        expect(caps[1].id, 'ha_runtime');
        expect(caps[1].version, 2);
      });

      test('given_empty_bytes_when_parsed_then_returns_empty_list', () {
        final caps = CapabilityReader.parseCapabilityBytes(Uint8List(0));
        expect(caps, isEmpty);
      });

      test('given_truncated_bytes_when_parsed_then_returns_partial', () {
        // Only count byte, no capability data
        final caps = CapabilityReader.parseCapabilityBytes(Uint8List.fromList([2]));
        expect(caps, isEmpty);
      });
    });
  });
}
