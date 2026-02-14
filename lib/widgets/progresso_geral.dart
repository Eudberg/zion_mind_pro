import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../data/disciplinas_mock.dart'; // Mantendo seu fallback original

class ProgressoGeral extends StatelessWidget {
  const ProgressoGeral({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrilhaController>(
      builder: (context, trilha, _) {
        // CORREÇÃO: Certifique-se de que esses getters existem no TrilhaController.
        // Se o erro persistir, abra o trilha_controller.dart e adicione:
        // int get totalMinutosPlanejados => _tarefas.fold(0, (sum, t) => sum + t.chPlanejadaMin);
        // int get totalMinutosEfetivos => _tarefas.fold(0, (sum, t) => sum + (t.chEfetivaMin ?? 0));

        final int totalMinutosEstudadosTrilha = trilha.totalMinutosEfetivos;
        final int totalMinutosPlanejadosTrilha = trilha.totalMinutosPlanejados;

        // Lógica de Fallback: Se não houver nada na trilha, usa os dados do Mock
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

        // Cálculo de progresso com proteção contra divisão por zero
        final double progresso = totalMinutosPlanejados == 0
            ? 0.0
            : (totalMinutosEstudados / totalMinutosPlanejados).clamp(0.0, 1.0);

        final int pct = (progresso * 100).toInt();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.05,
            ), // Compatibilidade com versões anteriores do Flutter
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progresso Geral',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Barra de progresso visual
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$pct% concluído',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${totalMinutosEstudados ~/ 60}h / ${totalMinutosPlanejados ~/ 60}h',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
