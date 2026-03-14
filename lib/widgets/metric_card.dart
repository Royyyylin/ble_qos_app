import 'package:flutter/material.dart';

/// Simple metric display card.
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            if (unit != null)
              Text(unit!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
