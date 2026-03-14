/// PEER_ROLE handshake values.
/// After BLE connection, Phone writes 0x02 to identify itself to ED.
/// See: docs/adr/2026-03-14-01-peer-identification-decision.md
class PeerRole {
  PeerRole._();

  static const int gw = 0x01;
  static const int phone = 0x02;
}
