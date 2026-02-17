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
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Pega pendentes e agrupa por nome da trilha (ex: "Trilha 0")
        final pendentes = controller.tarefas
            .where((t) => !t.concluida)
            .toList();

        if (pendentes.isEmpty) {
          return const Center(
            child: Text(
              "Nenhuma tarefa pendente.\nImporte sua trilha nas configurações.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        final grupos = <String, List<TarefaTrilha>>{};
        for (final t in pendentes) {
          final nome = (t.trilha == null || t.trilha!.trim().isEmpty)
              ? 'Sem trilha'
              : t.trilha!.trim();
          grupos.putIfAbsent(nome, () => []);
          grupos[nome]!.add(t);
        }

        // Ordena trilhas numericamente quando possível ("Trilha 0", "Trilha 1"...)
        final trilhasOrdenadas = grupos.keys.toList()
          ..sort((a, b) => _compareTrilhas(a, b));

        // Ordena tarefas dentro de cada trilha
        for (final k in trilhasOrdenadas) {
          grupos[k]!.sort((a, b) => a.ordemGlobal.compareTo(b.ordemGlobal));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: trilhasOrdenadas.length,
          itemBuilder: (context, index) {
            final nomeTrilha = trilhasOrdenadas[index];
            final tarefasDaTrilha = grupos[nomeTrilha]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              child: ExpansionTile(
                collapsedIconColor: Colors.white54,
                iconColor: Colors.white70,
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nomeTrilha.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${tarefasDaTrilha.length} tarefas',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _rangeLabel(tarefasDaTrilha),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                children: tarefasDaTrilha
                    .map((t) => _TarefaTile(tarefa: t))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }

  static int _compareTrilhas(String a, String b) {
    int? numA = _extractTrilhaIndex(a);
    int? numB = _extractTrilhaIndex(b);

    if (numA != null && numB != null) return numA.compareTo(numB);
    if (numA != null) return -1;
    if (numB != null) return 1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static int? _extractTrilhaIndex(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  static String _rangeLabel(List<TarefaTrilha> tarefas) {
    if (tarefas.isEmpty) return '';
    final ordens = tarefas.map((t) => t.ordemGlobal).toList()..sort();
    final min = ordens.first;
    final max = ordens.last;
    return 'Tarefas #$min – #$max';
  }
}

class _TarefaTile extends StatelessWidget {
  final TarefaTrilha tarefa;
  const _TarefaTile({required this.tarefa});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text(
          tarefa.assunto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (tarefa.descricao ?? '').trim().isEmpty
            ? null
            : Text(
                tarefa.descricao!.trim(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Text(
          '#${tarefa.ordemGlobal}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TarefaTrilhaDetalhe(tarefa: tarefa),
            ),
          );
          if (!context.mounted) return;
          await context.read<TrilhaController>().carregarTarefas();
        },
      ),
    );
  }
}
