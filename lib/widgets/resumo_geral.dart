import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/disciplinas_mock.dart';
import '../controllers/trilha_controller.dart';

class ResumoGeral extends StatelessWidget {
  const ResumoGeral({super.key});

  String _formatHoras(int totalMinutos) {
    final h = totalMinutos ~/ 60;
    final m = totalMinutos % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrilhaController>(
      builder: (context, trilha, _) {
        final totalMinutosTrilha = trilha.totalMinutosEfetivos;
        final totalMinutosFallback = disciplinasMock.fold<int>(
          0,
          (acc, d) => acc + d.minutosEstudados,
        );
        final totalMinutos =
            totalMinutosTrilha > 0 ? totalMinutosTrilha : totalMinutosFallback;

        final diasAtivos = trilha.diasAtivos;

        return Row(
          children: [
            Expanded(
              child: _ResumoCard(
                titulo: 'Horas estudadas',
                valor: _formatHoras(totalMinutos),
                icon: Icons.access_time,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ResumoCard(
                titulo: 'Dias ativos',
                valor: '$diasAtivos',
                icon: Icons.calendar_today,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(titulo),
        ],
      ),
    );
  }
}
