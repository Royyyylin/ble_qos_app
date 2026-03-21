import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_models.dart';
import '../gatt/gatt_structs.dart';
import 'device_provider.dart';
import 'scan_provider.dart';

/// An ED entry in the GW roster.
class EdRosterEntry {
  final ScannedDevice device;
  final QosStatus? gwStatus; // from indexed STATUS notify (null = not connected to GW)

  const EdRosterEntry({required this.device, this.gwStatus});

  bool get isConnectedToGw => gwStatus != null;
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

/// Combined ED roster: scan results + GW indexed STATUS.
/// Only active when connected to a GW.
final edRosterProvider = Provider<List<EdRosterEntry>>((ref) {
  final connDevice = ref.watch(connectedDeviceProvider);
  if (connDevice == null || connDevice.networkId == null) return const [];

  final networkId = connDevice.networkId!;
  final scanResults = ref.watch(scanResultsProvider);
  final edStatusMap = ref.watch(edStatusMapProvider);

  // Get all EDs in the same network
  final eds = scanResults
      .where((d) =>
          d.mfgData != null &&
          d.mfgData!.isEndDevice &&
          d.networkId == networkId)
      .toList();

  // Match scan order to ed_index (best-effort, Phase 2 firmware will expose roster with IDs)
  return eds.asMap().entries.map((entry) {
    final idx = entry.key;
    final device = entry.value;
    return EdRosterEntry(
      device: device,
      gwStatus: edStatusMap[idx],
    );
  }).toList();
});
