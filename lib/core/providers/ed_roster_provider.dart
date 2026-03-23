import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_models.dart';
import '../gatt/gatt_structs.dart';
import 'device_provider.dart';
import 'metrics_provider.dart';
import 'scan_provider.dart';

/// An ED entry in the GW roster.
class EdRosterEntry {
  final ScannedDevice device;
  final QosStatus? gwStatus; // from indexed STATUS notify (null = not connected to GW)
  final RosterEntry? rosterSlot; // from firmware ROSTER_LIST (null = not in roster)

  const EdRosterEntry({required this.device, this.gwStatus, this.rosterSlot});

  bool get isConnectedToGw => gwStatus != null || (rosterSlot != null && rosterSlot!.isOnline);
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

/// Combined ED roster: scan results + GW indexed STATUS + firmware ROSTER_LIST.
/// Uses MAC address matching between scan results and ROSTER_LIST for accurate status.
final edRosterProvider = Provider<List<EdRosterEntry>>((ref) {
  final connDevice = ref.watch(connectedDeviceProvider);
  if (connDevice == null || connDevice.networkId == null) return const [];

  final networkId = connDevice.networkId!;
  final scanResults = ref.watch(scanResultsProvider);
  final edStatusMap = ref.watch(edStatusMapProvider);

  // Get firmware roster (may be empty if characteristic not available)
  final rosterAsync = ref.watch(rosterListProvider);
  final rosterEntries = rosterAsync.valueOrNull ?? const [];

  // Build MAC → RosterEntry lookup (uppercase for matching)
  final rosterByMac = <String, RosterEntry>{};
  for (final r in rosterEntries) {
    if (!r.isEmpty) {
      rosterByMac[r.address.toUpperCase()] = r;
    }
  }

  // Build MAC → ed_index lookup for STATUS matching
  final rosterIndexByMac = <String, int>{};
  for (final r in rosterEntries) {
    if (!r.isEmpty) {
      rosterIndexByMac[r.address.toUpperCase()] = r.logicalSlot;
    }
  }

  // Get all EDs in the same network
  final eds = scanResults
      .where((d) =>
          d.mfgData != null &&
          d.mfgData!.isEndDevice &&
          d.networkId == networkId)
      .toList();

  // Sort by RSSI (strongest first) for stable ordering
  eds.sort((a, b) => b.smoothedRssi.compareTo(a.smoothedRssi));

  return eds.map((device) {
    // Match by MAC address to firmware roster
    final mac = device.mac?.toUpperCase();
    final rosterSlot = mac != null ? rosterByMac[mac] : null;
    // Match STATUS by roster slot index (more accurate than scan order)
    final slotIdx = mac != null ? rosterIndexByMac[mac] : null;
    final gwStatus = slotIdx != null ? edStatusMap[slotIdx] : null;

    return EdRosterEntry(
      device: device,
      gwStatus: gwStatus,
      rosterSlot: rosterSlot,
    );
  }).toList();
});
