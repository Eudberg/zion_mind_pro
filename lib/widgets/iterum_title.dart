import 'package:flutter/material.dart';

class IterumTitle extends StatelessWidget {
  final double iconSize;
  final double gap;

  const IterumTitle({super.key, this.iconSize = 26, this.gap = 10});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.autorenew_rounded, color: cs.primary, size: iconSize),
        SizedBox(width: gap),
        const Text(
          'Iterum',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ],
    );
  }
}
