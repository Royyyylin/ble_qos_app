/// DeviceIdentity aggregate — maps a platform MAC to an app-generated StableId (UUIDv4).
/// Invariants:
///   - Each MAC maps to exactly one StableId
///   - StableId is immutable once assigned
///   - MAC-to-StableId mapping is persisted across sessions
class DeviceIdentity {
  /// App-generated UUIDv4 stable identifier — primary key across all 9 touch points.
  final String stableId;

  /// Platform-specific BLE remote identifier (MAC on Android, UUID on iOS).
  /// Used only for FlutterBluePlus operations.
  final String mac;

  /// Timestamp when this identity was first assigned.
  final DateTime createdAt;

  DeviceIdentity({
    required this.stableId,
    required this.mac,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceIdentity &&
          stableId == other.stableId &&
          mac == other.mac;

  @override
  int get hashCode => Object.hash(stableId, mac);

  @override
  String toString() => 'DeviceIdentity(stableId: $stableId, mac: $mac)';
}
