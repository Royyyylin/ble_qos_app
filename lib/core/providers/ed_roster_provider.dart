import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_connector.dart';
import '../ble/ble_gatt.dart';
import '../ble/ble_models.dart';
import '../gatt/gatt_structs.dart';
import '../gatt/gatt_uuids.dart';
import 'device_provider.dart';
import 'scan_provider.dart';

/// An ED entry in the GW roster.
class EdRosterEntry {
  final ScannedDevice device;
  final QosStatus? gwStatus; // from indexed STATUS notify
  final EdListEntry? edListEntry; // from ED_LIST characteristic

  const EdRosterEntry({required this.device, this.gwStatus, this.edListEntry});

  bool get isConnectedToGw => edListEntry != null;
}

/// Accumulates indexed STATUS notifies into a per-ED map.
class EdStatusMapNotifier extends StateNotifier<Map<int, QosStatus>> {
  EdStatusMapNotifier() : super(const {});

  void update(QosStatus status) {
    state = {...state, status.edIndex: status};
  }

  void clear() {
    state = const {};
  }
}

final edStatusMapProvider =
    StateNotifierProvider<EdStatusMapNotifier, Map<int, QosStatus>>((ref) {
  return EdStatusMapNotifier();
});

/// GW's ED_LIST — reads connected EDs from the GW via GATT.
/// Returns list of EdListEntry (only connected slots).
class GwEdListNotifier extends StateNotifier<List<EdListEntry>> {
  GwEdListNotifier() : super(const []);

  void update(List<EdListEntry> entries) {
    state = entries;
  }

  void clear() {
    state = const [];
  }
}

final gwEdListProvider =
    StateNotifierProvider<GwEdListNotifier, List<EdListEntry>>((ref) {
  return GwEdListNotifier();
});

/// Reads ED_LIST from GW GATT and updates gwEdListProvider.
/// Call this after connecting to GW and periodically to refresh.
Future<void> refreshGwEdList(
    BleConnector connector, GwEdListNotifier notifier) async {
  try {
    final gatt = BleGatt(connector);
    final data = await gatt.read(GattUuids.edList);
    final entries = EdListEntry.parseList(data);
    notifier.update(entries);
  } catch (_) {
    // ED_LIST characteristic may not exist on ED devices
  }
}

/// Combined ED roster: scan results + GW ED_LIST + indexed STATUS.
/// Uses ED_LIST address matching (not scan order) for accurate mapping.
final edRosterProvider = Provider<List<EdRosterEntry>>((ref) {
  final connDevice = ref.watch(connectedDeviceProvider);
  if (connDevice == null || connDevice.networkId == null) return const [];

  final networkId = connDevice.networkId!;
  final scanResults = ref.watch(scanResultsProvider);
  final edStatusMap = ref.watch(edStatusMapProvider);
  final gwEdList = ref.watch(gwEdListProvider);

  // Get all scanned EDs in the same network
  final eds = scanResults
      .where((d) =>
          d.mfgData != null &&
          d.mfgData!.isEndDevice &&
          d.networkId == networkId)
      .toList();

  // Match scanned EDs to GW ED_LIST by BLE address
  return eds.map((device) {
    // Find this device in GW's ED_LIST by comparing MAC address
    final edEntry = gwEdList.cast<EdListEntry?>().firstWhere(
          (e) => e!.address.toUpperCase() == device.id.toUpperCase(),
          orElse: () => null,
        );
    // If found in ED_LIST, also get indexed STATUS by ed_index
    final status = edEntry != null ? edStatusMap[edEntry.edIndex] : null;

    return EdRosterEntry(
      device: device,
      gwStatus: status,
      edListEntry: edEntry,
    );
  }).toList();
});
