import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';
import 'tela_planejamento_dia.dart';

class TelaTrilha extends StatefulWidget {
  const TelaTrilha({super.key});

  @override
  State<TelaTrilha> createState() => _TelaTrilhaState();
}

class _TelaTrilhaState extends State<TelaTrilha> {
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<TrilhaController>().carregarTarefas(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Trilha Estrategica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaPlanejamentoDia(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.carregando
                            ? null
                            : () => controller.importarCsv(),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Importar CSV'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: controller.carregando
                          ? null
                          : () => controller.carregarTarefas(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (controller.erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.erro!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _buildLista(controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLista(TrilhaController controller) {
    if (controller.carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.tarefas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma tarefa importada ainda.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.tarefas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tarefa = controller.tarefas[index];
        return _buildCard(tarefa);
      },
    );
  }

  Widget _buildCard(TarefaTrilha tarefa) {
    final data = tarefa.dataPlanejada != null
        ? _dateFormat.format(tarefa.dataPlanejada!)
        : 'Sem data';
    final minutos = tarefa.chPlanejadaMin?.toString() ?? '--';
    final disciplina = tarefa.disciplina ?? 'Sem disciplina';
    final descricao = tarefa.descricao ?? 'Sem descricao';

    return InkWell(
      onTap: () => _mostrarDetalhes(tarefa),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              disciplina,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(label: data, icon: Icons.event),
                const SizedBox(width: 8),
                _InfoChip(label: '$minutos min', icon: Icons.timer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhes(TarefaTrilha tarefa) {
    final campos = _camposDetalhe(tarefa);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.separated(
            itemCount: campos.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = campos[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.key,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<MapEntry<String, String>> _camposDetalhe(TarefaTrilha tarefa) {
    String format(DateTime? d) =>
        d == null ? '-' : _dateFormat.format(d);

    return [
      MapEntry('Trilha', tarefa.trilha ?? '-'),
      MapEntry('Data planejada', format(tarefa.dataPlanejada)),
      MapEntry('Codigo', tarefa.tarefaCodigo ?? '-'),
      MapEntry('Disciplina', tarefa.disciplina ?? '-'),
      MapEntry('Descricao', tarefa.descricao ?? '-'),
      MapEntry('CH planejada (min)', tarefa.chPlanejadaMin?.toString() ?? '-'),
      MapEntry('CH efetiva (min)', tarefa.chEfetivaMin?.toString() ?? '-'),
      MapEntry('Questoes', tarefa.questoes?.toString() ?? '-'),
      MapEntry('Acertos', tarefa.acertos?.toString() ?? '-'),
      MapEntry(
        'Desempenho',
        tarefa.desempenho != null
            ? '${(tarefa.desempenho! * 100).toStringAsFixed(1)}%'
            : '-',
      ),
      MapEntry('Revisao 24h', format(tarefa.rev24h)),
      MapEntry('Revisao 7d', format(tarefa.rev7d)),
      MapEntry('Revisao 15d', format(tarefa.rev15d)),
      MapEntry('Revisao 30d', format(tarefa.rev30d)),
      MapEntry('Revisao 60d', format(tarefa.rev60d)),
      MapEntry('Extras', tarefa.jsonExtra ?? '-'),
      MapEntry('Hash', tarefa.hashLinha ?? '-'),
    ];
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
