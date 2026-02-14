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
              Icon(Icons.inbox, size: 48, color: Colors.grey[700]),
              const SizedBox(height: 16),
              Text(
                "Nenhuma tarefa por aqui.",
                style: TextStyle(color: Colors.grey[500]),
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

    // Lógica de Cores e Status
    Color statusColor = Colors.blue;
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
          statusColor = Colors.green;
          final days = revDateNormalized.difference(today).inDays;
          statusLabel = "AGENDADA (${days}d)";
        } else {
          // Aba Principal (Hoje ou Atrasada)
          if (revDateNormalized.isBefore(today)) {
            statusColor = Colors.red;
            statusLabel = "ATRASADA";
            isOverdue = true;
          } else {
            statusColor = Colors.amber;
            statusLabel = "REVISÃO HOJE";
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red : Colors.white.withOpacity(0.1),
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
                // Ícone
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tarefa.assunto,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
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

                // Botão de Check (Só aparece se NÃO for aba de revisões futuras)
                if (!isRevisaoTab)
                  IconButton(
                    icon: const Icon(
                      Icons.check_box_outline_blank,
                      color: Colors.grey,
                      size: 28,
                    ),
                    onPressed: () => _showCompletionDialog(context, tarefa),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Rodapé Metadata
            Row(
              children: [
                // Usando ID ou Ordem Global se preferir
                Text(
                  "#${tarefa.id}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),

                if (tarefa.estagioRevisao > 0) ...[
                  Icon(Icons.history, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    "Ciclo: ${tarefa.estagioRevisao == 1 ? '7d' : (tarefa.estagioRevisao == 2 ? '30d' : '60d')}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                ],

                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  "${tarefa.duracaoMinutos} min",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            tarefa.estagioRevisao == 0
                ? "Registrar Estudo"
                : "Registrar Revisão",
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tarefa.disciplina,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Tempo (min)",
                  labelStyle: TextStyle(color: Colors.blue[300]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Q. Feitas",
                        labelStyle: TextStyle(color: Colors.blue[300]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qCorrectController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Q. Certas",
                        labelStyle: TextStyle(color: Colors.green[300]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
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
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
              child: const Text(
                "Salvar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
