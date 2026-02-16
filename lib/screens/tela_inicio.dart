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
  Future<void> _abrirTarefa(TarefaTrilha tarefa) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TarefaTrilhaDetalhe(tarefa: tarefa),
      ),
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
    final sugestoes = controller.sugestoesPlanoDia;
    final prioridade = controller.prioridadePendentes;
    final proximaAcao = prioridade.isNotEmpty ? prioridade.first : null;
    final progressoMeta = controller.metaMinutosDia > 0
        ? (controller.minutosHoje / controller.metaMinutosDia).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Constancia'),
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
                      color: ativo ? Colors.greenAccent : Colors.white24,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.streakAtual} dias em sequencia | Recorde: ${controller.recordeStreak}',
            style: const TextStyle(color: Colors.white70),
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
                  _ResumoLinha('Minutos semana (7d)', '${controller.minutosSemana}'),
                  _ResumoLinha('Pendentes', '${controller.tarefasPendentes.length}'),
                  _ResumoLinha(
                    'Revisoes atrasadas/hoje',
                    '${controller.revisoesAtrasadasOuHoje.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
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
            backgroundColor: Colors.white12,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 6),
          Text(
            '${controller.minutosHoje} / ${controller.metaMinutosDia} min',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 10),
          if (sugestoes.isEmpty)
            const Text(
              'Sem sugestoes para hoje.',
              style: TextStyle(color: Colors.white54),
            ),
          ...sugestoes.map(
            (t) => Card(
              child: ListTile(
                title: Text(t.disciplina),
                subtitle: Text('${t.assunto} - ${t.chPlanejadaMin} min'),
                trailing: TextButton(
                  onPressed: () => _abrirTarefa(t),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Proxima acao'),
          const SizedBox(height: 10),
          if (proximaAcao == null)
            const Text(
              'Nenhuma acao pendente.',
              style: TextStyle(color: Colors.white54),
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
                    Text('${proximaAcao.assunto} - ${proximaAcao.chPlanejadaMin} min'),
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
                            child: const Text('Iniciar cronometro'),
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
      style: const TextStyle(
        color: Colors.white,
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
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
