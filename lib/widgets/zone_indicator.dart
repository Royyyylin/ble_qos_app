import 'package:flutter/material.dart';

/// Zone color badge: NEAR=green, MID=blue, FAR=orange, EDGE=red.
class ZoneIndicator extends StatelessWidget {
  const ZoneIndicator({super.key, required this.zone});

  final int zone;

  static const _labels = ['NEAR', 'MID', 'FAR', 'EDGE'];
  static const _colors = [Colors.green, Colors.blue, Colors.orange, Colors.red];

  @override
  Widget build(BuildContext context) {
    final idx = zone.clamp(0, 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colors[idx],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[idx],
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
