import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../data/disciplinas_mock.dart';

class ProgressoGeral extends StatelessWidget {
  const ProgressoGeral({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrilhaController>(
      builder: (context, trilha, _) {
        final totalMinutosEstudadosTrilha = trilha.totalMinutosEfetivos;
        final totalMinutosPlanejadosTrilha = trilha.totalMinutosPlanejados;

        final totalMinutosEstudadosFallback = disciplinasMock.fold<int>(
          0,
          (acc, d) => acc + d.minutosEstudados,
        );
        final totalMinutosPlanejadosFallback = disciplinasMock.fold<int>(
          0,
          (acc, d) => acc + (d.cargaHorariaTotal * 60),
        );

        final totalMinutosEstudados = totalMinutosPlanejadosTrilha > 0
            ? totalMinutosEstudadosTrilha
            : totalMinutosEstudadosFallback;
        final totalMinutosPlanejados = totalMinutosPlanejadosTrilha > 0
            ? totalMinutosPlanejadosTrilha
            : totalMinutosPlanejadosFallback;

        final progresso = totalMinutosPlanejados == 0
            ? 0.0
            : (totalMinutosEstudados / totalMinutosPlanejados)
                .clamp(0.0, 1.0);

        final pct = (progresso * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso Geral',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progresso),
              const SizedBox(height: 8),
              Text('$pct% do planejamento concluido'),
            ],
          ),
        );
      },
    );
  }
}
