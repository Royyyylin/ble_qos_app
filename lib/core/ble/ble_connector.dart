import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gatt/gatt_peer_role.dart';
import '../gatt/gatt_uuids.dart';
import 'backoff_config.dart';
import 'ble_models.dart';
import 'ble_reconnect.dart';
import 'ble_service_utils.dart';

/// BLE connector — handles connect + PEER_ROLE handshake.
/// Detects unexpected disconnection and delegates to [BleReconnect] for
/// automatic reconnection with exponential backoff.
class BleConnector {
  StreamSubscription<BluetoothConnectionState>? _connSub;
  BluetoothDevice? _device;
  List<BluetoothService>? _services;
  BleConnectionState _state = BleConnectionState.disconnected;
  final _stateController = StreamController<BleConnectionState>.broadcast();
  bool _intentionalDisconnect = false;
  BleReconnect? _reconnect;

  Stream<BleConnectionState> get stateStream => _stateController.stream;
  BleConnectionState get state => _state;
  String? get connectedDeviceId => _device?.remoteId.str;
  BluetoothDevice? get device => _device;
  List<BluetoothService>? get services => _services;

  /// Attach a [BleReconnect] instance for auto-reconnect on unexpected disconnect.
  set reconnect(BleReconnect? r) => _reconnect = r;

  void _setState(BleConnectionState s) {
    _state = s;
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  /// Connect to device, discover services, and perform PEER_ROLE Handshake.
  /// Completes only after Handshake succeeds or an error occurs.
  /// On failure, transitions to [BleConnectionState.error].
  Future<void> connect(String deviceId) async {
    _intentionalDisconnect = false;
    _reconnect?.cancel();
    _setState(BleConnectionState.connecting);
    _device = BluetoothDevice.fromId(deviceId);

    final completer = Completer<void>();

    _connSub?.cancel();
    _connSub = _device!.connectionState.listen(
      (connState) async {
        if (connState == BluetoothConnectionState.connected) {
          try {
            _services = await _device!.discoverServices();
            await _performHandshake();
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            _services = null;
            _setState(BleConnectionState.error);
            await _device?.disconnect();
            if (!completer.isCompleted) completer.completeError(e);
          }
        } else if (connState == BluetoothConnectionState.disconnected) {
          _services = null;
          final wasConnected = _state == BleConnectionState.connected;
          if (_state != BleConnectionState.error) {
            _setState(BleConnectionState.disconnected);
          }
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('Device disconnected during connection'),
            );
          }
          // Auto-reconnect on unexpected disconnection
          if (wasConnected && !_intentionalDisconnect && _reconnect != null) {
            _reconnect!.startReconnect(deviceId);
          }
        }
      },
      onError: (e) {
        _services = null;
        _setState(BleConnectionState.error);
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      await _device!.connect(timeout: const Duration(seconds: 10));
      await completer.future;
    } catch (_) {
      if (_state == BleConnectionState.connecting ||
          _state == BleConnectionState.handshaking) {
        _setState(BleConnectionState.error);
      }
      rethrow;
    }
  }

  /// Write PEER_ROLE = 0x02 (Phone) after connection established.
  Future<void> _performHandshake() async {
    _setState(BleConnectionState.handshaking);
    try {
      final char = _findCharacteristic(GattUuids.peerRole);
      if (char != null) {
        await char.write([PeerRole.phone]);
      }
      _setState(BleConnectionState.connected);
    } catch (_) {
      // Handshake failed — stay connected but peer is UNKNOWN (permissive)
      _setState(BleConnectionState.connected);
    }
  }

  /// Find a characteristic by UUID string in discovered services.
  BluetoothCharacteristic? _findCharacteristic(String charUuid) =>
      findCharacteristicByUuid(_services, charUuid);

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnect?.cancel();
    _connSub?.cancel();
    _connSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _services = null;
    _setState(BleConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }
}

/// Riverpod provider for the connector.
final bleConnectorProvider = Provider<BleConnector>((ref) {
  final connector = BleConnector();
  ref.onDispose(() => connector.dispose());
  return connector;
});

/// StreamProvider for BleConnectionState — used by ConnectionStateIndicator.
final bleConnectionStateProvider = StreamProvider<BleConnectionState>((ref) {
  final connector = ref.watch(bleConnectorProvider);
  return connector.stateStream;
});

/// Riverpod provider for BleReconnect with Exponential Backoff.
/// Automatically wired into [BleConnector] for unexpected disconnection detection.
final bleReconnectProvider = Provider<BleReconnect>((ref) {
  final connector = ref.watch(bleConnectorProvider);
  final reconnect = BleReconnect(
    connect: (deviceId) => connector.connect(deviceId),
    isDisconnected: () =>
        connector.state == BleConnectionState.disconnected ||
        connector.state == BleConnectionState.error,
    config: const BackoffConfig(),
  );
  // Wire reconnect into connector for auto-reconnect on unexpected disconnect
  connector.reconnect = reconnect;
  ref.onDispose(() {
    connector.reconnect = null;
    reconnect.dispose();
  });
  return reconnect;
});
