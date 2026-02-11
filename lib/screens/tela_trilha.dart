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

  String _grupoKey(TarefaTrilha t) {
    // Regra principal: trilha = floor((ordemGlobal-1)/25)
    final og = t.ordemGlobal;
    if (og != null && og > 0) {
      final idx = (og - 1) ~/ 25; // 0,1,2...
      return 'TRILHA $idx';
    }

    // Fallback: usa o campo "trilha" se existir
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
    final tarefas = controller.tarefas;

    // Agrupa por trilha
    final Map<String, List<TarefaTrilha>> grupos = {};
    for (final t in tarefas) {
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
          ? const Center(child: Text('Importe uma trilha (CSV) para começar.'))
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
    final yy = d.year.toString();
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
        final codigo = codigoGlobal(t);
        final isSpecial = t.isDescanso || t.isLimparErros;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TarefaTrilhaDetalhe(tarefa: t),
                  ),
                );
                if (changed == true) {
                  await controller.carregarTarefas();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSpecial ? Icons.bedtime : Icons.assignment_outlined,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleMedium,
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
                              _Pill(
                                icon: Icons.calendar_today,
                                text: _fmtDate(t.dataPlanejada),
                              ),
                              _Pill(
                                icon: Icons.timer,
                                text: _fmtMin(t.chPlanejadaMin),
                              ),
                              if (t.concluida)
                                const _Pill(
                                  icon: Icons.check_circle,
                                  text: 'Concluída',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(text)],
      ),
    );
  }
}
