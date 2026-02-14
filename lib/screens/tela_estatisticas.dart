import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/trilha_controller.dart';

/// ESTA É A CLASSE QUE ESTAVA FALTANDO: TelaEstatisticas
/// Certifique-se de que o nome está exatamente assim.
class TelaEstatisticas extends StatelessWidget {
  const TelaEstatisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          // Buscamos as métricas calculadas no Controller
          final metricas = controller.metricasPorMateria;

          if (metricas.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum dado para exibir.\nImporte sua trilha e registre estudos.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "Tempo Estudado (min)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Geramos os cards de progresso para cada matéria
              ...metricas.entries.map(
                (e) => _MateriaProgressoCard(
                  nome: e.key,
                  progresso: e.value['progresso']!,
                  minRealizado: e.value['minutosRealizados']!.toInt(),
                  minTotal: e.value['minutosPlanejados']!.toInt(),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                "Desempenho (Questões)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Geramos as linhas de precisão de acertos
              ...metricas.entries.map(
                (e) => _MateriaPrecisaoRow(
                  nome: e.key,
                  precisao: e.value['precisao']!,
                ),
              ),
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
                "${(progresso * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.white10,
            color: Colors.blueAccent,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            "$minRealizado min de $minTotal min previstos",
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
            "${(precisao * 100).toInt()}%",
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
