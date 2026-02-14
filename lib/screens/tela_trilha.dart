import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';
import 'tarefa_trilha_detalhe.dart';

class TelaTrilha extends StatelessWidget {
  const TelaTrilha({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrilhaController>(
      builder: (context, controller, _) {
        // Mostra um carregando enquanto o banco de dados é lido
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Obtém o mapa de tarefas agrupadas por blocos de 25
        final grupos = controller.tarefasAgrupadasPorTrilha;

        if (grupos.isEmpty) {
          return const Center(
            child: Text(
              "Nenhuma tarefa pendente.\nImporte sua trilha nas configurações.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        // Ordenamos as trilhas (0, 1, 2...) para exibição sequencial
        final trilhasOrdenadas = grupos.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: trilhasOrdenadas.length,
          itemBuilder: (context, index) {
            final numTrilha = trilhasOrdenadas[index];
            final tarefasDaTrilha = grupos[numTrilha]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO DA TRILHA (Ex: TRILHA 0, TRILHA 1)
                _buildHeaderTrilha(numTrilha, tarefasDaTrilha.length),

                // MAPEAMENTO DAS TAREFAS DENTRO DESTE GRUPO
                ...tarefasDaTrilha.map((t) => _TarefaCard(tarefa: t)),

                const SizedBox(height: 24), // Espaçamento entre as trilhas
              ],
            );
          },
        );
      },
    );
  }

  // Widget de cabeçalho para as seções de 25 tarefas
  Widget _buildHeaderTrilha(int numero, int total) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trilha Estratégica",
            style: TextStyle(
              color: Colors.blue[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                "TRILHA $numero",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$total tarefas",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10, thickness: 1),
        ],
      ),
    );
  }
}

class _TarefaCard extends StatelessWidget {
  final TarefaTrilha tarefa;
  const _TarefaCard({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E293B), // Slate 800 para o fundo do card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        // CORREÇÃO: Habilita o clique em toda a área do card
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navega para a tela de detalhes passando a tarefa selecionada
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TarefaTrilhaDetalhe(tarefa: tarefa),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tarefa.disciplina.toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "##${tarefa.ordemGlobal}  ${tarefa.chPlanejadaMin} min",
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ASSUNTO: Mapeado para mostrar a descrição vinda do CSV
              Text(
                tarefa.assunto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if ((tarefa.descricao ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  tarefa.descricao!.trim(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildTag(
                    _formatDuracao(tarefa.chPlanejadaMin),
                    Colors.white12,
                  ),
                  const SizedBox(width: 8),
                  _buildTag(
                    "NOVA",
                    Colors.green.withOpacity(0.2),
                    textColor: Colors.greenAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuracao(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h == 0) return '${m}m';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  // Widget auxiliar para as etiquetas decorativas do card
  Widget _buildTag(
    String label,
    Color bgColor, {
    Color textColor = Colors.white60,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
