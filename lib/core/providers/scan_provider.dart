import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_models.dart';

/// Global scan results — persists across scanner start/stop so Roster tab can read.
class ScanResultsNotifier extends StateNotifier<List<ScannedDevice>> {
  ScanResultsNotifier() : super(const []);

  void update(List<ScannedDevice> devices) {
    state = devices;
  }

  void clear() {
    state = const [];
  }

  /// Get all EDs in the same network as [networkId].
  List<ScannedDevice> edsForNetwork(int networkId) {
    return state
        .where((d) =>
            d.mfgData != null &&
            d.mfgData!.isEndDevice &&
            d.networkId == networkId)
        .toList();
  }
}

final scanResultsProvider =
    StateNotifierProvider<ScanResultsNotifier, List<ScannedDevice>>((ref) {
  return ScanResultsNotifier();
});
