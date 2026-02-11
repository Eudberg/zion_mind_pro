import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../data/trilha_importer.dart';
import '../database/tarefas_trilha_dao.dart';
import '../database/revisoes_dao.dart';
import '../models/tarefa_trilha.dart';
import '../models/plano_item.dart';
import '../models/revisao.dart';

class TrilhaController extends ChangeNotifier {
  final _tarefasDao = TarefasTrilhaDao();
  final _revisoesDao = RevisoesDao();
  final _importer = TrilhaImporter();

  List<TarefaTrilha> _tarefas = [];
  List<TarefaTrilha> get tarefas => _tarefas;

  // Dia selecionado no “Planejamento do Dia”
  DateTime dataSelecionada = _dateOnly(DateTime.now());

  // Itens do dia
  List<PlanoItem> _planoDoDia = [];
  List<PlanoItem> get planoDoDia => _planoDoDia;

  // Revisões do dia (7/30/60)
  List<Revisao> _revisoesDoDia = [];
  List<Revisao> get revisoesDoDia => _revisoesDoDia;

  Future<void> carregarTarefas() async {
    _tarefas = await _tarefasDao.listarTodas();
    notifyListeners();
  }

  Future<void> importarCsv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    await importarCsvBytes(bytes);
  }

  Future<void> importarCsvBytes(Uint8List bytes) async {
    final tarefas = await _importer.importarBytes(bytes);

    // Apaga trilha anterior (se você quiser “acumular”, troque isso)
    await _tarefasDao.limparTudo();
    await _revisoesDao.limparTudo();

    // Insere em lote
    await _tarefasDao.inserirEmLote(tarefas);

    await carregarTarefas();
    await gerarPlanoDoDia(data: dataSelecionada);
  }

  Future<void> alternarConcluida(TarefaTrilha tarefa, bool concluida) async {
    if (tarefa.id == null) return;

    await _tarefasDao.atualizarConcluida(tarefa.id!, concluida);

    // Se marcou concluída, gera revisões 7/30/60; se desmarcou, limpa
    await _revisoesDao.limparPorTarefa(tarefa.id!);

    if (concluida) {
      final hoje = _dateOnly(DateTime.now());
      await _revisoesDao.inserirEmLote([
        Revisao(
          tarefaId: tarefa.id!,
          tipo: '7d',
          dataPrevista: hoje.add(const Duration(days: 7)),
          status: 'pendente',
        ),
        Revisao(
          tarefaId: tarefa.id!,
          tipo: '30d',
          dataPrevista: hoje.add(const Duration(days: 30)),
          status: 'pendente',
        ),
        Revisao(
          tarefaId: tarefa.id!,
          tipo: '60d',
          dataPrevista: hoje.add(const Duration(days: 60)),
          status: 'pendente',
        ),
      ]);
    }

    await carregarTarefas();
    await gerarPlanoDoDia(data: dataSelecionada);
  }

  Future<void> selecionarDia(DateTime dia) async {
    dataSelecionada = _dateOnly(dia);
    await gerarPlanoDoDia(data: dataSelecionada);
  }

  /// Planejamento do dia:
  /// - tarefas com data_planejada == dia
  /// - revisões previstas no dia (7/30/60)
  Future<void> gerarPlanoDoDia({required DateTime data}) async {
    final dia = _dateOnly(data);

    final tarefasDoDia = await _tarefasDao.listarPorDataPlanejada(dia);
    _planoDoDia = tarefasDoDia.map((t) => PlanoItem.fromTarefa(t)).toList();

    _revisoesDoDia = await _revisoesDao.listarPorData(dia);

    notifyListeners();
  }

  /// Usado pela tela de detalhe (questões/acertos/fonte/concluída).
  Future<void> atualizarTarefaCampos({
    required int tarefaId,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    bool? concluida,
  }) async {
    await _tarefasDao.atualizarCampos(
      tarefaId: tarefaId,
      questoes: questoes,
      acertos: acertos,
      fonteQuestoes: fonteQuestoes,
      concluida: concluida,
    );

    // se concluiu via detalhe, gera revisões
    if (concluida == true) {
      await _revisoesDao.limparPorTarefa(tarefaId);

      final hoje = _dateOnly(DateTime.now());
      await _revisoesDao.inserirEmLote([
        Revisao(
          tarefaId: tarefaId,
          tipo: '7d',
          dataPrevista: hoje.add(const Duration(days: 7)),
          status: 'pendente',
        ),
        Revisao(
          tarefaId: tarefaId,
          tipo: '30d',
          dataPrevista: hoje.add(const Duration(days: 30)),
          status: 'pendente',
        ),
        Revisao(
          tarefaId: tarefaId,
          tipo: '60d',
          dataPrevista: hoje.add(const Duration(days: 60)),
          status: 'pendente',
        ),
      ]);
    }

    await carregarTarefas();
    await gerarPlanoDoDia(data: dataSelecionada);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
