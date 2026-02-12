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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Carrega o plano (sem data = hoje)
      context.read<TrilhaController>().gerarPlanoDoDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Planejamento do Dia'),
        actions: [
          // Botãozinho extra para forçar atualização se precisar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TrilhaController>().gerarPlanoDoDia(),
          ),
        ],
      ),
      body: Consumer<TrilhaController>(
        builder: (context, controller, _) {
          final data = controller.dataSelecionada;
          final itens = controller.planoDoDia;

          final tarefasDia = itens
              .where((item) => item.tipo == 'estudo')
              .toList();
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
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    // Mostra total de tarefas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${tarefasDia.length + revisoes.length} Meta",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- LISTA DE TAREFAS ---
                Expanded(
                  child: ListView(
                    children: [
                      _SectionTitle(
                        title: 'Tarefas do dia',
                        count: tarefasDia.length,
                      ),
                      const SizedBox(height: 12),
                      if (tarefasDia.isEmpty)
                        const _EmptyCard(
                          text: 'Nenhuma tarefa planejada para hoje.',
                        ),
                      if (tarefasDia.isNotEmpty)
                        ...tarefasDia.map((item) => _PlanoCard(item: item)),

                      const SizedBox(height: 20),

                      _SectionTitle(
                        title: 'Revisões do dia',
                        count: revisoes.length,
                      ),
                      const SizedBox(height: 12),
                      if (revisoes.isEmpty)
                        const _EmptyCard(text: 'Nenhuma revisão prevista.'),
                      if (revisoes.isNotEmpty)
                        ...revisoes.map((item) => _PlanoCard(item: item)),

                      const SizedBox(height: 40), // Espaço final
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

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
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
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// --- AQUI ESTÁ A CLASSE QUE VOCÊ PROCURAVA (AGORA TURBINADA) ---
class _PlanoCard extends StatelessWidget {
  final PlanoItem item;

  const _PlanoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Usamos watch para o card reagir quando a tarefa mudar (ex: ficar verde)
    final controller = context.watch<TrilhaController>();

    // Busca a tarefa real no mapa do controller
    final tarefa = item.tarefaId != null
        ? controller.tarefasPorId[item.tarefaId!]
        : null;

    final titulo = tarefa?.disciplina ?? 'Tarefa';
    final descricao = tarefa?.descricao ?? 'Sem descrição';
    final minutos = item.minutosSugeridos?.toString() ?? '--';
    final tipo = item.tipo ?? 'estudo';

    // Dados de conclusão
    final dataConclusao = tarefa?.dataConclusao;
    final estaConcluido = tarefa?.concluida ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: estaConcluido
            ? const Color(0xFF0F172A).withOpacity(0.8) // Mais escuro se feito
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estaConcluido
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone
          Icon(
            tipo == 'estudo' ? Icons.book : Icons.history,
            size: 20,
            color: estaConcluido ? Colors.green : Colors.white70,
          ),
          const SizedBox(width: 12),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: estaConcluido
                        ? TextDecoration.lineThrough
                        : null,
                    color: estaConcluido ? Colors.white54 : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: estaConcluido ? Colors.white38 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tipo.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- O BOTÃO MÁGICO DE DATA/CONCLUIR ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  // Prepara data inicial
                  final dataAtual = dataConclusao != null
                      ? DateTime.parse(dataConclusao)
                      : DateTime.now();

                  // Abre Calendário
                  final novaData = await showDatePicker(
                    context: context,
                    initialDate: dataAtual,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    // locale: const Locale('pt', 'BR'), // Descomente se tiver configurado
                  );

                  // Salva se escolheu
                  if (novaData != null && tarefa?.id != null) {
                    controller.editarDataConclusao(tarefa!.id!, novaData);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estaConcluido
                        ? Colors.green
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        estaConcluido
                            ? Icons.edit_calendar
                            : Icons.check_circle_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estaConcluido
                            ? DateFormat(
                                'dd/MM',
                              ).format(DateTime.parse(dataConclusao!))
                            : 'Concluir',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$minutos min',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
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
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }
}
