import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/periodo_metrica.dart';

class TelaEstatisticas extends StatefulWidget {
  const TelaEstatisticas({super.key});

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  PeriodoMetrica _periodoSelecionado = PeriodoMetrica.total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          final metricas = controller.metricasPorMateriaPeriodo(_periodoSelecionado);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ToggleButtons(
                isSelected: [
                  _periodoSelecionado == PeriodoMetrica.hoje,
                  _periodoSelecionado == PeriodoMetrica.semana,
                  _periodoSelecionado == PeriodoMetrica.mes,
                  _periodoSelecionado == PeriodoMetrica.total,
                ],
                onPressed: (index) {
                  setState(() {
                    _periodoSelecionado = PeriodoMetrica.values[index];
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Hoje'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Semana'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Mes'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Total'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (metricas.isEmpty)
                const Center(
                  child: Text(
                    'Nenhum dado para exibir neste periodo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              else ...[
                const Text(
                  'Tempo Estudado (min)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...metricas.entries.map(
                  (e) => _MateriaProgressoCard(
                    nome: e.key,
                    progresso: e.value['progresso'] ?? 0.0,
                    minRealizado: (e.value['minutosRealizados'] ?? 0).toInt(),
                    minTotal: (e.value['minutosPlanejados'] ?? 0).toInt(),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Desempenho (Questoes)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...metricas.entries.map(
                  (e) => _MateriaPrecisaoRow(
                    nome: e.key,
                    precisao: e.value['precisao'] ?? 0.0,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MateriaProgressoCard extends StatelessWidget {
  final String nome;
  final double progresso;
  final int minRealizado;
  final int minTotal;

  const _MateriaProgressoCard({
    required this.nome,
    required this.progresso,
    required this.minRealizado,
    required this.minTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progresso * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progresso.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: Colors.blueAccent,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '$minRealizado min de $minTotal min previstos',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MateriaPrecisaoRow extends StatelessWidget {
  final String nome;
  final double precisao;

  const _MateriaPrecisaoRow({required this.nome, required this.precisao});

  @override
  Widget build(BuildContext context) {
    final pct = (precisao * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nome,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              color: precisao > 0.7 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
