import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';
import '../widgets/discipline_status_list.dart';

class TelaRevisoes extends StatelessWidget {
  const TelaRevisoes({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TrilhaController>(context);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final programadas = controller.revisoesProgramadas;
    final atrasadasHoje = controller.revisoesAtrasadasOuHoje;
    final concluidas = controller.revisoesConcluidas;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Programadas'),
              Tab(text: 'Atrasadas-Hoje'),
              Tab(text: 'Concluidas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RevisaoTabContent(
                  tarefas: programadas,
                  isRevisaoTab: true,
                  onRefresh: controller.carregarTarefas,
                ),
                _RevisaoTabContent(
                  tarefas: atrasadasHoje,
                  isRevisaoTab: false,
                  onRefresh: controller.carregarTarefas,
                ),
                _RevisaoTabContent(
                  tarefas: concluidas,
                  isRevisaoTab: true,
                  onRefresh: controller.carregarTarefas,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevisaoTabContent extends StatelessWidget {
  final List<TarefaTrilha> tarefas;
  final bool isRevisaoTab;
  final Future<void> Function() onRefresh;

  const _RevisaoTabContent({
    required this.tarefas,
    required this.isRevisaoTab,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            DisciplineStatusList(
              tarefas: tarefas,
              isRevisaoTab: isRevisaoTab,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
