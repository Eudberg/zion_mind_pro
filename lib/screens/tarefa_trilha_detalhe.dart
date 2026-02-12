import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import necessário para formatar data
import 'package:provider/provider.dart';

import '../controllers/trilha_controller.dart';
import '../models/tarefa_trilha.dart';

class TarefaTrilhaDetalhe extends StatefulWidget {
  final TarefaTrilha tarefa;

  const TarefaTrilhaDetalhe({super.key, required this.tarefa});

  @override
  State<TarefaTrilhaDetalhe> createState() => _TarefaTrilhaDetalheState();
}

class _TarefaTrilhaDetalheState extends State<TarefaTrilhaDetalhe> {
  late final TextEditingController _questoesCtrl;
  late final TextEditingController _acertosCtrl;

  bool _concluida = false;
  String? _fonte; // 'pdf' | 'sistema' | null

  // Variável local para data de conclusão (para atualizar na tela instantaneamente)
  DateTime? _dataConclusaoLocal;

  @override
  void initState() {
    super.initState();
    _questoesCtrl = TextEditingController(
      text: widget.tarefa.questoes?.toString() ?? '',
    );
    _acertosCtrl = TextEditingController(
      text: widget.tarefa.acertos?.toString() ?? '',
    );
    _concluida = widget.tarefa.concluida;
    _fonte = widget.tarefa.fonteQuestoes;

    // Inicializa data local se existir no banco
    if (widget.tarefa.dataConclusao != null) {
      _dataConclusaoLocal = DateTime.tryParse(widget.tarefa.dataConclusao!);
    }
  }

  @override
  void dispose() {
    _questoesCtrl.dispose();
    _acertosCtrl.dispose();
    super.dispose();
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _salvar() async {
    final questoes = _parseInt(_questoesCtrl.text);
    final acertos = _parseInt(_acertosCtrl.text);

    if (questoes != null && questoes < 0) {
      _toast('Questões não pode ser negativo.');
      return;
    }
    if (acertos != null && acertos < 0) {
      _toast('Acertos não pode ser negativo.');
      return;
    }
    if (questoes != null && acertos != null && acertos > questoes) {
      _toast('Acertos não pode ser maior que Questões.');
      return;
    }

    if (widget.tarefa.id == null) {
      _toast('ID da tarefa não encontrado.');
      return;
    }

    await context.read<TrilhaController>().atualizarTarefaCampos(
      tarefaId: widget.tarefa.id!,
      questoes: questoes,
      acertos: acertos,
      fonteQuestoes: _fonte,
      concluida: _concluida,
      dataConclusao: _dataConclusaoLocal, // Salva a data que o usuário escolheu
    );

    if (mounted) Navigator.pop(context, true);
  }

  // Função para abrir o calendário
  Future<void> _selecionarData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _dataConclusaoLocal ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      // locale: const Locale('pt', 'BR'), // Se configurado
    );

    if (novaData != null) {
      setState(() {
        _dataConclusaoLocal = novaData;
        _concluida = true; // Se escolheu data, marca como feito automaticamente
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarefa;
    final desempenho = t.desempenhoCalculado;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.disciplina ?? 'Tarefa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvar,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passamos a função de selecionar data para o Header
            _Header(
              tarefa: t,
              dataConclusao: _dataConclusaoLocal,
              onTapData: _selecionarData,
            ),
            const SizedBox(height: 16),
            Text('Descrição', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              t.descricao?.trim().isNotEmpty == true ? t.descricao! : '—',
            ),
            const SizedBox(height: 16),
            Text('Questões', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questoesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      hintText: 'Ex: 20',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _acertosCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Acertos',
                      hintText: 'Ex: 14',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Fonte das questões',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('PDF/Aula'),
                  selected: _fonte == 'pdf',
                  onSelected: (_) =>
                      setState(() => _fonte = _fonte == 'pdf' ? null : 'pdf'),
                ),
                ChoiceChip(
                  label: const Text('Sistema de questões'),
                  selected: _fonte == 'sistema',
                  onSelected: (_) => setState(
                    () => _fonte = _fonte == 'sistema' ? null : 'sistema',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _concluida,
              onChanged: (v) => setState(() => _concluida = v ?? false),
              title: const Text('Concluir tarefa'),
              subtitle: const Text(
                'Ao concluir, serão geradas revisões em 7/30/60 dias.',
              ),
            ),
            const SizedBox(height: 16),
            if (desempenho != null)
              Row(
                children: [
                  Expanded(child: LinearProgressIndicator(value: desempenho)),
                  const SizedBox(width: 12),
                  Text('${(desempenho * 100).toStringAsFixed(0)}%'),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TarefaTrilha tarefa;
  final DateTime? dataConclusao; // Recebe a data atualizada da tela
  final VoidCallback onTapData; // Recebe a função de abrir calendário

  const _Header({
    required this.tarefa,
    required this.dataConclusao,
    required this.onTapData,
  });

  String _fmtDate(DateTime? d) {
    if (d == null) return '—'; // Retorna traço se não tiver data
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    // final yy = d.year.toString(); // Ano opcional
    return '$dd/$mm';
  }

  String _fmtMin(int? min) {
    if (min == null) return '—';
    final h = min ~/ 60;
    final m = min % 60;
    if (h <= 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (tarefa.trilha ?? 'TRILHA').toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tarefa.disciplina ?? '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Chip do NÚMERO (Corrigido: Sem # #)
                Chip(
                  avatar: const Icon(Icons.tag, size: 18),
                  label: Text(
                    tarefa.ordemGlobal != null
                        ? '${tarefa.ordemGlobal}' // Só o número
                        : (tarefa.tarefaCodigo ?? '—'),
                  ),
                ),

                // 2. Chip da DATA (Agora clicável e mostra data de conclusão se houver)
                ActionChip(
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: dataConclusao != null ? Colors.green : null,
                  ),
                  label: Text(
                    dataConclusao != null
                        ? _fmtDate(dataConclusao) // Mostra 12/02
                        : 'Sem data', // Mostra "Sem data" em vez de "-"
                    style: TextStyle(
                      color: dataConclusao != null ? Colors.green : null,
                      fontWeight: dataConclusao != null
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                  onPressed: onTapData, // Abre o calendário
                ),

                // 3. Chip do TEMPO Planejado
                Chip(
                  avatar: const Icon(Icons.timelapse, size: 18),
                  label: Text(_fmtMin(tarefa.chPlanejadaMin)),
                ),

                // 4. Chip do TEMPO Efetivo
                Chip(
                  avatar: const Icon(Icons.timer, size: 18),
                  label: Text(_fmtMin(tarefa.chEfetivaMin)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
