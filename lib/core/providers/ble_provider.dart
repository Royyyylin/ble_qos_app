import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single FlutterReactiveBle instance shared across the app.
final bleInstanceProvider = Provider<FlutterReactiveBle>((ref) {
  return FlutterReactiveBle();
});
