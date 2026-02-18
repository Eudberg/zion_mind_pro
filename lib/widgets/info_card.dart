//info_card.dart//

import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final Color cor;

  const InfoCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(color: cor, fontSize: 12)),
        ],
      ),
    );
  }
}
