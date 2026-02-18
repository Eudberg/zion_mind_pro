import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tarefa_trilha.dart';
import '../controllers/trilha_controller.dart';

class DisciplineStatusList extends StatelessWidget {
  final List<TarefaTrilha> tarefas;
  final bool isRevisaoTab; // Para saber se muda a cor/comportamento

  const DisciplineStatusList({
    super.key,
    required this.tarefas,
    this.isRevisaoTab = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tarefas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                "Nenhuma tarefa por aqui.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tarefas.length,
      itemBuilder: (context, index) {
        final tarefa = tarefas[index];
        return _buildCard(context, tarefa);
      },
    );
  }

  Widget _buildCard(BuildContext context, TarefaTrilha tarefa) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // LÃ³gica de Cores e Status
    Color statusColor = const Color(0xFF2563EB);
    String statusLabel = "NOVA";
    bool isOverdue = false;

    if (tarefa.estagioRevisao > 0) {
      if (tarefa.dataProximaRevisao != null) {
        final revDate = tarefa.dataProximaRevisao!;
        final revDateNormalized = DateTime(
          revDate.year,
          revDate.month,
          revDate.day,
        );

        if (isRevisaoTab) {
          // Aba Futura
          statusColor = const Color(0xFF10B981);
          final days = revDateNormalized.difference(today).inDays;
          statusLabel = "AGENDADA (${days}d)";
        } else {
          // Aba Principal (Hoje ou Atrasada)
          if (revDateNormalized.isBefore(today)) {
            statusColor = const Color(0xFFEF4444);
            statusLabel = "ATRASADA";
            isOverdue = true;
          } else {
            statusColor = const Color(0xFFF59E0B);
            statusLabel = "REVISÃƒO HOJE";
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).dividerColor,
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ãcone
                Icon(
                  tarefa.estagioRevisao > 0 ? Icons.loop : Icons.assignment,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 12),

                // Texto Principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.disciplina,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tarefa.assunto,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      // Label de Status
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BotÃ£o de Check (SÃ³ aparece se NÃƒO for aba de revisÃµes futuras)
                if (!isRevisaoTab)
                  IconButton(
                    icon: Icon(
                      Icons.check_box_outline_blank,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    onPressed: () => _showCompletionDialog(context, tarefa),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // RodapÃ© Metadata
            Row(
              children: [
                // Usando ID ou Ordem Global se preferir
                Text(
                  "#${tarefa.id}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),

                if (tarefa.estagioRevisao > 0) ...[
                  Icon(
                    Icons.history,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Ciclo: ${tarefa.estagioRevisao == 1 ? '7d' : (tarefa.estagioRevisao == 2 ? '30d' : '60d')}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  "${tarefa.duracaoMinutos} min",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, TarefaTrilha tarefa) {
    final TextEditingController timeController = TextEditingController(
      text: tarefa.duracaoMinutos.toString(),
    );
    final TextEditingController qTotalController = TextEditingController();
    final TextEditingController qCorrectController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            tarefa.estagioRevisao == 0
                ? "Registrar Estudo"
                : "Registrar RevisÃ£o",
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tarefa.disciplina,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Tempo (min)",
                  labelStyle: TextStyle(
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(ctx).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qTotalController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Q. Feitas",
                        labelStyle: TextStyle(
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(ctx).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qCorrectController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Q. Certas",
                        labelStyle: TextStyle(
                          color: Theme.of(ctx).colorScheme.secondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(ctx).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(ctx).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancelar",
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final minutos = int.tryParse(timeController.text) ?? 0;
                final total = int.tryParse(qTotalController.text) ?? 0;
                final acertos = int.tryParse(qCorrectController.text) ?? 0;

                // Chama o controller real para salvar
                Provider.of<TrilhaController>(
                  context,
                  listen: false,
                ).registrarConclusao(tarefa, minutos, total, acertos);

                Navigator.pop(ctx);
              },
              child: Text(
                "Salvar",
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
            ),
          ],
        );
      },
    );
  }
}
