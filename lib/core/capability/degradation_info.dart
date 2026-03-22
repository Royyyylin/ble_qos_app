/// Metadata about an incompatible capability for Graceful Degradation UI.
/// Shown as a warning badge + tooltip on the affected tab.
class DegradationInfo {
  final String capId;
  final int deviceVersion;
  final int requiredVersion;
  final String tabLabel;

  const DegradationInfo({
    required this.capId,
    required this.deviceVersion,
    required this.requiredVersion,
    required this.tabLabel,
  });

  /// Human-readable degradation message for tooltip display.
  String get message =>
      '$capId: device has v$deviceVersion, requires v$requiredVersion';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DegradationInfo &&
          capId == other.capId &&
          deviceVersion == other.deviceVersion &&
          requiredVersion == other.requiredVersion &&
          tabLabel == other.tabLabel;

  @override
  int get hashCode =>
      Object.hash(capId, deviceVersion, requiredVersion, tabLabel);

  @override
  String toString() => 'DegradationInfo($message)';
}
