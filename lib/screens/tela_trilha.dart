import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';
import 'tarefa_trilha_detalhe.dart';

class TelaTrilha extends StatefulWidget {
  const TelaTrilha({super.key});

  @override
  State<TelaTrilha> createState() => _TelaTrilhaState();
}

class _TelaTrilhaState extends State<TelaTrilha> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TrilhaController>().carregarTarefas());
  }

  // --- LÓGICA DE AGRUPAMENTO (Mantida igual) ---
  String _grupoKey(TarefaTrilha t) {
    final og = t.ordemGlobal;
    if (og != null && og > 0) {
      final idx = (og - 1) ~/ 25;
      return 'TRILHA $idx';
    }
    final raw = (t.trilha ?? '').trim();
    if (raw.isEmpty) return 'SEM TRILHA';
    final up = raw.toUpperCase();
    final n = RegExp(r'(\d+)').firstMatch(up)?.group(1);
    if (n != null) return 'TRILHA ${int.parse(n)}';
    return up;
  }

  int _grupoOrder(String key) {
    final m = RegExp(r'(\d+)').firstMatch(key);
    if (m != null) return int.parse(m.group(1)!);
    return 9999;
  }

  int _ordem(TarefaTrilha t) =>
      (t.ordemGlobal != null && t.ordemGlobal! > 0) ? t.ordemGlobal! : 999999;

  String _codigoGlobal(TarefaTrilha t) {
    final og = t.ordemGlobal;
    if (og == null || og <= 0) return '—';
    return '# $og';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrilhaController>();

    // MUDANÇA 1: Usa 'tarefasVisiveis' em vez de todas.
    // Se quiser ver TODAS (incluindo concluídas), troque por controller.tarefas
    // Mas você pediu para sumir as concluídas, então use controller.tarefasVisiveis.
    // SE O GETTER AINDA NÃO EXISTIR NO CONTROLLER, USE controller.tarefas POR ENQUANTO.
    final tarefas = controller.tarefasVisiveis;

    // Agrupa por trilha
    final Map<String, List<TarefaTrilha>> grupos = {};
    for (final t in tarefas) {
      // Se quiser filtrar aqui na mão enquanto o getter não existe:
      // if (t.concluida) continue;

      final k = _grupoKey(t);
      grupos.putIfAbsent(k, () => []).add(t);
    }

    final chaves = grupos.keys.toList()
      ..sort((a, b) => _grupoOrder(a).compareTo(_grupoOrder(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trilha Estratégica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: () => controller.carregarTarefas(),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar CSV',
            onPressed: () async {
              await controller.importarCsv();
              if (mounted) await controller.carregarTarefas();
            },
          ),
        ],
      ),
      body: tarefas.isEmpty
          ? const Center(child: Text('Nenhuma tarefa pendente na trilha.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final key in chaves) ...[
                  _GrupoHeader(titulo: key, total: grupos[key]!.length),
                  const SizedBox(height: 8),
                  _GrupoLista(
                    tarefas: (grupos[key]!
                      ..sort((a, b) => _ordem(a).compareTo(_ordem(b)))),
                    codigoGlobal: _codigoGlobal,
                    ordemGlobal: _ordem,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}

class _GrupoHeader extends StatelessWidget {
  final String titulo;
  final int total;
  const _GrupoHeader({required this.titulo, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$total'),
        ),
      ],
    );
  }
}

class _GrupoLista extends StatelessWidget {
  final List<TarefaTrilha> tarefas;
  final String Function(TarefaTrilha) codigoGlobal;
  final int Function(TarefaTrilha) ordemGlobal;

  const _GrupoLista({
    required this.tarefas,
    required this.codigoGlobal,
    required this.ordemGlobal,
  });

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Sem data';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString(); // 2024
    // Se quiser abreviar ano: yy.substring(2)
    return '$dd/$mm/$yy';
  }

  String _fmtMin(int? min) {
    if (min == null) return '-- min';
    return '${min} min';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TrilhaController>();

    return Column(
      children: tarefas.map((t) {
        final titulo = (t.disciplina ?? 'Sem disciplina').toUpperCase();
        final desc = (t.descricao ?? 'Sem descrição').trim();

        // MUDANÇA 2: Ajuste no código visual
        final codigo = t.ordemGlobal != null
            ? '# ${t.ordemGlobal}'
            : (t.tarefaCodigo ?? '-');

        final isSpecial = t.isDescanso || t.isLimparErros;

        // MUDANÇA 3: Data inteligente (Mostra Conclusão se tiver, senão Planejada)
        final DateTime? dataMostrada = t.dataConclusao != null
            ? DateTime.tryParse(t.dataConclusao!)
            : t.dataPlanejada;

        final bool temDataConclusao = t.dataConclusao != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            // Cor de Fundo: Se for revisão futura, pode mudar aqui
            // color: t.isRevisao ? Colors.orange.shade50 : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // MUDANÇA 4: Navegação com refresh garantido
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TarefaTrilhaDetalhe(tarefa: t),
                  ),
                );

                // Se voltou da tela de detalhes (mesmo sem salvar explicitamente), recarrega
                // para atualizar datas ou remover da lista se foi concluída
                await controller.carregarTarefas();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSpecial ? Icons.bedtime : Icons.assignment_outlined,
                      size: 22,
                      color: temDataConclusao ? Colors.green : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  decoration: t.concluida
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: t.concluida ? Colors.grey : null,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            desc.isEmpty ? '—' : desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Pill(icon: Icons.numbers, text: codigo),

                              // Pill da DATA (Verde se concluída)
                              _Pill(
                                icon: Icons.calendar_today,
                                text: _fmtDate(dataMostrada),
                                color: temDataConclusao
                                    ? Colors.green.withOpacity(0.1)
                                    : null,
                                textColor: temDataConclusao
                                    ? Colors.green
                                    : null,
                              ),

                              _Pill(
                                icon: Icons.timer,
                                text: _fmtMin(t.chPlanejadaMin),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Checkbox para concluir rápido direto na lista
                    Checkbox(
                      value: t.concluida,
                      onChanged: (v) =>
                          controller.alternarConcluida(t, v ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color; // Novo parâmetro
  final Color? textColor; // Novo parâmetro

  const _Pill({
    required this.icon,
    required this.text,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
