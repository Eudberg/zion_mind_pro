import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/trilha_controller.dart';
import '../widgets/discipline_status_list.dart';

class TelaRevisoes extends StatelessWidget {
  const TelaRevisoes({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumindo o Controller para obter os dados atualizados
    final controller = Provider.of<TrilhaController>(context);

    // Estado de Carregamento
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Obtém a lista filtrada apenas para revisões futuras
    final revisoesFuturas = controller.revisoesFuturas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho Simples
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Agendadas (${revisoesFuturas.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Ícone informativo opcional
              Tooltip(
                message: "Tarefas que aparecerão na trilha no dia agendado.",
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Lista de Revisões
        Expanded(
          child: RefreshIndicator(
            onRefresh:
                controller.carregarTarefas, // Permite puxar pra atualizar
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Renderiza a lista de cards configurada para "Revisão"
                  // (Isso muda as cores para verde e esconde o botão de check)
                  DisciplineStatusList(
                    tarefas: revisoesFuturas,
                    isRevisaoTab: true,
                  ),
                  const SizedBox(height: 32), // Espaço extra no final
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
