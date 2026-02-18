import 'package:flutter/material.dart';
import '../models/disciplina.dart';

class ListaDisciplinas extends StatelessWidget {
  final List<Disciplina> disciplinas;
  final Function(Disciplina) onTap;

  const ListaDisciplinas({
    super.key,
    required this.disciplinas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (disciplinas.isEmpty) {
      return Center(
        child: Text(
          "Nenhuma disciplina encontrada.\nImporte a trilha no ícone acima.",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disciplinas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ...disciplinas.map((d) => _buildItem(context, d)).toList(),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Disciplina d) {
    // Lógica simples de cor baseada no progresso
    Color cor = Theme.of(context).colorScheme.primary;
    String status = "Iniciando";

    if (d.progresso >= 1.0) {
      cor = Theme.of(context).colorScheme.secondary;
      status = "Concluída";
    } else if (d.progresso > 0.5) {
      cor = const Color(0xFFF59E0B);
      status = "Em andamento";
    } else if (d.progresso == 0) {
      cor = Theme.of(context).colorScheme.error;
      status = "Não iniciada";
    }

    return GestureDetector(
      onTap: () => onTap(d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    d.nome,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${(d.progresso * 100).toInt()}%",
                    style: TextStyle(
                      color: cor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: d.progresso,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                color: cor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

