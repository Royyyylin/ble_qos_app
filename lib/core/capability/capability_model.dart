/// A device capability — spec §5.1.
class Capability {
  final String id;
  final int version;

  const Capability({required this.id, required this.version});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Capability && id == other.id && version == other.version;

  @override
  int get hashCode => Object.hash(id, version);

  @override
  String toString() => 'Capability($id v$version)';
}
