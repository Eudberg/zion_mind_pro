import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/estudo_controller.dart';
import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';
import 'tarefa_trilha_detalhe.dart';
import 'tela_cronometro.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  Future<void> _atualizarDados() async {
    await context.read<TrilhaController>().carregarTarefas();
  }

  Future<void> _abrirTarefa(TarefaTrilha tarefa) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TarefaTrilhaDetalhe(tarefa: tarefa)),
    );
    if (!mounted) return;
    await context.read<TrilhaController>().carregarTarefas();
  }

  Future<void> _iniciarCronometro(TarefaTrilha tarefa) async {
    context.read<EstudoController>().iniciarSessaoTarefa(tarefa);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaCronometro()),
    );
    if (!mounted) return;
    await context.read<TrilhaController>().carregarTarefas();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrilhaController>();
    final prioridade = controller.prioridadePendentes;
    final proximaAcao = prioridade.isNotEmpty ? prioridade.first : null;

    final progressoMeta = controller.metaMinutosDia > 0
        ? (controller.minutosHoje / controller.metaMinutosDia).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _atualizarDados,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Constância'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: controller.ultimos14DiasAtivos
                  .map(
                    (ativo) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ativo
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.24),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.streakAtual} dias de estudo em sequência. Recorde: ${controller.recordeStreak}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            const _SectionTitle('Resumo'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _ResumoLinha('Minutos hoje', '${controller.minutosHoje}'),
                    _ResumoLinha(
                      'Minutos semana (7d)',
                      '${controller.minutosSemana}',
                    ),
                    _ResumoLinha(
                      'Pendentes',
                      '${controller.tarefasPendentes.length}',
                    ),
                    _ResumoLinha(
                      'Revisões atrasadas',
                      '${controller.revisoesAtrasadasOuHoje.length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // =========================
            // PLANEJAMENTO DO DIA (NOVO)
            // =========================
            const _SectionTitle('Planejamento do dia'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [60, 90, 120, 150, 180]
                  .map(
                    (m) => ChoiceChip(
                      label: Text('$m min'),
                      selected: controller.metaMinutosDia == m,
                      onSelected: (_) => controller.setMetaMinutosDia(m),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progressoMeta,
              minHeight: 8,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.12),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              '${controller.minutosHoje} / ${controller.metaMinutosDia} min',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<TarefaTrilha>>(
              future: controller.getPlanoHoje(),
              builder: (context, snapshot) {
                final plano = snapshot.data ?? [];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Plano de hoje',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (plano.isNotEmpty)
                              Text(
                                '${plano.length} itens',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (plano.isEmpty) ...[
                          Text(
                            'Nenhum plano montado ainda.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await controller.gerarPlanoHoje();
                                if (!mounted) return;
                                setState(() {});
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Montar plano do dia'),
                            ),
                          ),
                        ] else ...[
                          ...plano.map(
                            (t) => Card(
                              child: ListTile(
                                  title: Text(
                                  t.disciplina,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${t.assunto} - ${t.chPlanejadaMin} min',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _abrirTarefa(t),
                                      child: const Text('Abrir'),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      tooltip: 'Iniciar cronômetro',
                                      icon: const Icon(Icons.play_circle_fill),
                                      onPressed: () => _iniciarCronometro(t),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await controller.gerarPlanoHoje();
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                  child: const Text('Refazer'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await controller.limparPlanoHoje();
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                  child: const Text('Limpar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),
            const _SectionTitle('Próxima Tarefa'),
            const SizedBox(height: 10),
            if (proximaAcao == null)
              Text(
                'Nenhuma Tarefa pendente.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proximaAcao.disciplina,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${proximaAcao.assunto} - ${proximaAcao.chPlanejadaMin} min',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _abrirTarefa(proximaAcao),
                              child: const Text('Abrir tarefa'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _iniciarCronometro(proximaAcao),
                              child: const Text('Iniciar cronômetro'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoLinha(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
