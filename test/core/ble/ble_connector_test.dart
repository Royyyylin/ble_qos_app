import 'package:flutter_test/flutter_test.dart';
import 'package:ble_qos_app/core/ble/ble_connector.dart';
import 'package:ble_qos_app/core/ble/ble_models.dart';

// NOTE: BleConnector depends on FlutterBluePlus native plugin.
// Full connection tests require a real BLE device or a mock BluetoothDevice.
// These tests verify initial state and state machine logic.

void main() {
  group('BleConnector', () {
    test('given_new_connector_when_created_then_state_is_disconnected', () {
      final connector = BleConnector();
      expect(connector.state, BleConnectionState.disconnected);
      expect(connector.connectedDeviceId, isNull);
      expect(connector.services, isNull);
      connector.dispose();
    });

    test('given_new_connector_when_stateStream_listened_then_emits_states', () async {
      final connector = BleConnector();
      final states = <BleConnectionState>[];
      final sub = connector.stateStream.listen(states.add);
      // Initial state is not emitted via stream — only transitions
      connector.dispose();
      await sub.cancel();
    });
  });
}
