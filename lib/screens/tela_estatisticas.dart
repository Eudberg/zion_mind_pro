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
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          final metricas = controller.metricasPorMateriaPeriodo(
            _periodoSelecionado,
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _IterumLogotypeCard(),
              const SizedBox(height: 20),
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
                    child: Text('Mês'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Total'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (metricas.isEmpty)
                Center(
                  child: Text(
                    'Nenhum dado para exibir neste perÃ­odo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else ...[
                Text(
                  'Tempo Estudado (min)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                Text(
                  'Desempenho (Questões)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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

class _IterumLogotypeCard extends StatelessWidget {
  const _IterumLogotypeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1530),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CustomPaint(
                painter: _IterumCircularIArrowPainter(),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'terum',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IterumCircularIArrowPainter extends CustomPainter {
  const _IterumCircularIArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const emerald = Color(0xFF10B981);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;
    final strokeWidth = size.width * 0.14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ringPaint = Paint()
      ..color = emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.55, 4.95, false, ringPaint);

    final arrowBase = Offset(
      center.dx + radius * 0.94,
      center.dy + radius * 0.28,
    );
    final arrowPath = Path()
      ..moveTo(arrowBase.dx, arrowBase.dy)
      ..lineTo(arrowBase.dx - size.width * 0.16, arrowBase.dy - size.width * 0.04)
      ..lineTo(arrowBase.dx - size.width * 0.05, arrowBase.dy - size.width * 0.15)
      ..close();
    canvas.drawPath(
      arrowPath,
      Paint()..color = emerald,
    );

    final stemPaint = Paint()
      ..color = emerald
      ..style = PaintingStyle.fill;
    final stemRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.16,
        height: size.height * 0.62,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(stemRect, stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progresso * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progresso.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.1),
            color: Theme.of(context).colorScheme.primary,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '$minRealizado min de $minTotal min previstos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              color: precisao > 0.7
                  ? Theme.of(context).colorScheme.secondary
                  : const Color(0xFFF59E0B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
