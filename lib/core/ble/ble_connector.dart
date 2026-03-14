import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_peer_role.dart';
import '../gatt/gatt_uuids.dart';
import 'ble_models.dart';
import 'ble_scanner.dart' show bleProvider;

/// BLE connector — handles connect + PEER_ROLE handshake.
class BleConnector {
  BleConnector(this._ble);

  final FlutterReactiveBle _ble;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  String? _connectedDeviceId;
  BleConnectionState _state = BleConnectionState.disconnected;
  final _stateController = StreamController<BleConnectionState>.broadcast();

  Stream<BleConnectionState> get stateStream => _stateController.stream;
  BleConnectionState get state => _state;
  String? get connectedDeviceId => _connectedDeviceId;

  void _setState(BleConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  /// Connect to device and perform PEER_ROLE handshake.
  Future<void> connect(String deviceId) async {
    _setState(BleConnectionState.connecting);
    _connectedDeviceId = deviceId;

    _connSub?.cancel();
    _connSub = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
      (update) async {
        if (update.connectionState == DeviceConnectionState.connected) {
          await _performHandshake(deviceId);
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          _setState(BleConnectionState.disconnected);
          _connectedDeviceId = null;
        }
      },
      onError: (_) {
        _setState(BleConnectionState.disconnected);
        _connectedDeviceId = null;
      },
    );
  }

  /// Write PEER_ROLE = 0x02 (Phone) after connection established.
  Future<void> _performHandshake(String deviceId) async {
    _setState(BleConnectionState.handshaking);
    try {
      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(GattUuids.serviceQos),
        characteristicId: Uuid.parse(GattUuids.peerRole),
        deviceId: deviceId,
      );
      await _ble.writeCharacteristicWithResponse(
        characteristic,
        value: [PeerRole.phone],
      );
      _setState(BleConnectionState.connected);
    } catch (_) {
      // Handshake failed — stay connected but peer is UNKNOWN (permissive)
      _setState(BleConnectionState.connected);
    }
  }

  void disconnect() {
    _connSub?.cancel();
    _connSub = null;
    _connectedDeviceId = null;
    _setState(BleConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }
}

/// Riverpod provider for the connector.
final bleConnectorProvider = Provider<BleConnector>((ref) {
  final ble = ref.watch(bleProvider);
  final connector = BleConnector(ble);
  ref.onDispose(() => connector.dispose());
  return connector;
});

// bleProvider is defined in ble_scanner.dart — import from there.
