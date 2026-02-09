import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/plano_item.dart';

class TelaPlanejamentoDia extends StatefulWidget {
  const TelaPlanejamentoDia({super.key});

  @override
  State<TelaPlanejamentoDia> createState() => _TelaPlanejamentoDiaState();
}

class _TelaPlanejamentoDiaState extends State<TelaPlanejamentoDia> {
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<TrilhaController>().gerarPlanoDoDia(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Planejamento do Dia'),
      ),
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          final data = controller.dataSelecionada;
          final itens = controller.planoDoDia;
          final tarefasDia =
              itens.where((item) => item.tipo == 'estudo').toList();
          final revisoes = itens
              .where((item) => item.tipo != null && item.tipo != 'estudo')
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _dateFormat.format(data),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => controller.gerarPlanoDoDia(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Tarefas do dia',
                  count: tarefasDia.length,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      if (tarefasDia.isEmpty)
                        _EmptyCard(text: 'Nenhuma tarefa planejada.'),
                      if (tarefasDia.isNotEmpty)
                        ...tarefasDia.map((item) => _PlanoCard(item: item)),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: 'Revisoes do dia',
                        count: revisoes.length,
                      ),
                      const SizedBox(height: 12),
                      if (revisoes.isEmpty)
                        _EmptyCard(text: 'Nenhuma revisao prevista.'),
                      if (revisoes.isNotEmpty)
                        ...revisoes.map((item) => _PlanoCard(item: item)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PlanoCard extends StatelessWidget {
  final PlanoItem item;

  const _PlanoCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TrilhaController>();
    final tarefa = item.tarefaId != null
        ? controller.tarefasPorId[item.tarefaId!]
        : null;

    final titulo = tarefa?.disciplina ?? 'Tarefa';
    final descricao = tarefa?.descricao ?? 'Sem descricao';
    final minutos = item.minutosSugeridos?.toString() ?? '--';
    final tipo = item.tipo ?? 'estudo';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tipo == 'estudo' ? Icons.book : Icons.history,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  tipo.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$minutos min',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}
