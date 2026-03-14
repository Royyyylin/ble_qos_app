/// App connection modes.
/// See: docs/plans/2026-03-14-02-app-spec-vnext-scope.md
enum ConnectionMode {
  /// Phone connects to GW — sees all EDs via indexed GATT
  gwAggregate,

  /// Phone connects directly to ED — sees single ED
  edDirect,
}
