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
    return Consumer<TrilhaController>(
      builder: (context, controller, _) {
        final metricas = controller.metricasPorMateriaPeriodo(
          _periodoSelecionado,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _PeriodoSegmented(
              value: _periodoSelecionado,
              onChanged: (novo) => setState(() => _periodoSelecionado = novo),
            ),
            const SizedBox(height: 20),

            if (metricas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'Nenhum dado para exibir neste período.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
else ...[
              _TempoExpansionCard(
                metricas: metricas,
                initiallyExpanded: _periodoSelecionado != PeriodoMetrica.total,
              ),
              const SizedBox(height: 12),
              _DesempenhoExpansionCard(
                metricas: metricas,
                initiallyExpanded: _periodoSelecionado != PeriodoMetrica.total,
              ),
            ]
          ],
        );
      },
    );
  }
}

/// Segmented control premium (Material 3), usando Theme.
/// Primary = emerald (selecionado).
class _PeriodoSegmented extends StatelessWidget {
  final PeriodoMetrica value;
  final ValueChanged<PeriodoMetrica> onChanged;

  const _PeriodoSegmented({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.10)),
      ),
      child: SegmentedButton<PeriodoMetrica>(
        segments: const [
          ButtonSegment(value: PeriodoMetrica.hoje, label: Text('Hoje')),
          ButtonSegment(value: PeriodoMetrica.semana, label: Text('Semana')),
          ButtonSegment(value: PeriodoMetrica.mes, label: Text('Mês')),
          ButtonSegment(value: PeriodoMetrica.total, label: Text('Total')),
        ],
        selected: {value},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected))
              return cs.primary; // emerald
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected))
              return cs.onPrimary; // branco
            return cs.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progresso * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: cs.primary, // emerald (tema)
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0),
              backgroundColor: cs.onSurface.withOpacity(0.10),
              color: cs.primary,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$minRealizado min de $minTotal min previstos',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
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
    final cs = Theme.of(context).colorScheme;
    final pct = (precisao * 100).toStringAsFixed(0);

    // Se você adotou primary=emerald, secondary=blue:
    // - bom: emerald (primary)
    // - ruim: warning
    final cor = precisao >= 0.70 ? cs.primary : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nome,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$pct%',
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
class _TempoExpansionCard extends StatelessWidget {
final Map<String, Map<String, dynamic>> metricas;
  final bool initiallyExpanded;

  const _TempoExpansionCard({
    required this.metricas,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    int totalMin = 0;
    String? topMateria;
    int topMin = -1;

    for (final e in metricas.entries) {
      final num minNum = (e.value['minutosRealizados'] ?? 0) as num;
      final int min = minNum.toInt();

      totalMin += min;

      if (min > topMin) {
        topMin = min;
        topMateria = e.key;
      }
    }


    return Card(
      child: Theme(
        // remove divisores feios do ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Tempo estudado',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            topMateria == null
                ? '$totalMin min no período'
                : '$totalMin min • Top: $topMateria ($topMin min)',
            style: TextStyle(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
          children: [
            const SizedBox(height: 6),
            ...metricas.entries.map(
              (e) => _MateriaProgressoCard(
                nome: e.key,
                progresso: (e.value['progresso'] ?? 0.0) as double,
                minRealizado: (e.value['minutosRealizados'] ?? 0).toInt(),
                minTotal: (e.value['minutosPlanejados'] ?? 0).toInt(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesempenhoExpansionCard extends StatelessWidget {
final Map<String, Map<String, dynamic>> metricas;
  final bool initiallyExpanded;

  const _DesempenhoExpansionCard({
    required this.metricas,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    double soma = 0.0;
    int count = 0;

    String? topMateria;
    double topPrec = -1;

    for (final e in metricas.entries) {
      final p = (e.value['precisao'] ?? 0.0) as double;
      soma += p;
      count += 1;
      if (p > topPrec) {
        topPrec = p;
        topMateria = e.key;
      }
    }

    final media = count == 0 ? 0.0 : soma / count;
    final mediaPct = (media * 100).toStringAsFixed(0);
    final topPct = topPrec < 0 ? '0' : (topPrec * 100).toStringAsFixed(0);

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Desempenho',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            topMateria == null
                ? 'Média: $mediaPct%'
                : 'Média: $mediaPct% • Top: $topMateria ($topPct%)',
            style: TextStyle(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
          children: [
            const SizedBox(height: 6),
            ...metricas.entries.map(
              (e) => _MateriaPrecisaoRow(
                nome: e.key,
                precisao: (e.value['precisao'] ?? 0.0) as double,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

