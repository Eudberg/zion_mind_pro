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
    return Column(
      children: disciplinas.map((disciplina) {
        return GestureDetector(
          onTap: () => onTap(disciplina),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disciplina.nome,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: disciplina.progresso),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
