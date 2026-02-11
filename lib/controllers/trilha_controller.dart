import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/trilha_importer.dart';
import '../database/plano_diario_dao.dart';
import '../database/revisoes_dao.dart';
import '../database/tarefas_trilha_dao.dart';
import '../models/disciplina.dart';
import '../models/plano_item.dart';
import '../models/revisao.dart';
import '../models/tarefa_trilha.dart';

class TrilhaController extends ChangeNotifier {
  final TarefasTrilhaDao _tarefasDao;
  final PlanoDiarioDao _planoDao;
  final RevisoesDao _revisoesDao;

  List<TarefaTrilha> tarefas = [];
  List<PlanoItem> planoDoDia = [];
  List<Revisao> revisoesDoDia = [];
  DateTime dataSelecionada = DateTime.now();

  bool carregando = false;
  String? erro;

  TrilhaController({
    TarefasTrilhaDao? tarefasDao,
    PlanoDiarioDao? planoDao,
    RevisoesDao? revisoesDao,
  }) : _tarefasDao = tarefasDao ?? TarefasTrilhaDao(),
       _planoDao = planoDao ?? PlanoDiarioDao(),
       _revisoesDao = revisoesDao ?? RevisoesDao();

  Future<void> carregarTarefas() async {
    tarefas = await _tarefasDao.listarTodas();
    notifyListeners();
  }

  Map<int, TarefaTrilha> get tarefasPorId {
    final map = <int, TarefaTrilha>{};
    for (final t in tarefas) {
      final id = t.id;
      if (id == null) {
        continue;
      }
      map[id] = t;
    }
    return map;
  }

  int get totalMinutosPlanejados =>
      tarefas.fold(0, (acc, t) => acc + (t.chPlanejadaMin ?? 0));

  int get totalMinutosEfetivos =>
      tarefas.fold(0, (acc, t) => acc + (t.chEfetivaMin ?? 0));

  int get diasAtivos {
    final dias = <String>{};
    for (final t in tarefas) {
      final minEfetivos = t.chEfetivaMin ?? 0;
      if (!t.concluida && minEfetivos <= 0) {
        continue;
      }
      final d = t.dataPlanejada;
      if (d == null) {
        continue;
      }
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      dias.add(key);
    }
    return dias.length;
  }

  // Dashboard por disciplina (progresso por tarefas concluídas)
  List<Disciplina> get disciplinasDoCsv {
    final total = <String, int>{};
    final done = <String, int>{};

    for (final t in tarefas) {
      final nome = (t.disciplina ?? '').trim();
      if (nome.isEmpty) continue;
      total[nome] = (total[nome] ?? 0) + 1;
      if (t.concluida) done[nome] = (done[nome] ?? 0) + 1;
    }

    final nomes = total.keys.toList()..sort();
    return nomes.map((nome) {
      return Disciplina.fromTarefas(
        nome: nome,
        totalTarefas: total[nome] ?? 0,
        tarefasConcluidas: done[nome] ?? 0,
      );
    }).toList();
  }

  Future<void> importarCsv() async {
    carregando = true;
    erro = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        carregando = false;
        notifyListeners();
        return;
      }

      Uint8List? bytes = result.files.single.bytes;
      final path = result.files.single.path;
      if (bytes == null && path != null) {
        bytes = await File(path).readAsBytes();
      }
      if (bytes == null) throw Exception('Nao foi possivel ler o arquivo.');

      final importer = TrilhaImporter();
      tarefas = await importer.importarBytes(bytes, limparAntes: true);

      await gerarPlanoDoDia(data: DateTime.now());
    } catch (e) {
      erro = e.toString();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // ✅ planejamento estável com pendências acumuladas
  Future<void> gerarPlanoDoDia({DateTime? data}) async {
    final alvo = _dateOnly(data ?? DateTime.now());
    dataSelecionada = alvo;

    if (tarefas.isEmpty) {
      tarefas = await _tarefasDao.listarTodas();
    }

    final pendentes = await _tarefasDao.listarPendentesAte(alvo);
    final revisoesDia = await _revisoesDao.listarPorData(alvo);

    await _planoDao.limparPorData(alvo);

    final itens = <PlanoItem>[];

    for (final tarefa in pendentes) {
      itens.add(
        PlanoItem(
          data: alvo,
          tarefaId: tarefa.id,
          tipo: 'estudo',
          minutosSugeridos: tarefa.chPlanejadaMin ?? 30,
          status: 'pendente',
        ),
      );
    }

    for (final revisao in revisoesDia) {
      itens.add(
        PlanoItem(
          data: alvo,
          tarefaId: revisao.tarefaId,
          tipo: 'revisao_${revisao.tipo}',
          minutosSugeridos: 20,
          status: 'pendente',
        ),
      );
    }

    if (itens.isNotEmpty) {
      await _planoDao.inserirEmLote(itens);
    }

    planoDoDia = await _planoDao.listarPorData(alvo);
    revisoesDoDia = revisoesDia;
    notifyListeners();
  }

  // usado pela sua TelaTrilha (checkbox)
  Future<void> alternarConcluida(TarefaTrilha tarefa, bool value) async {
    if (tarefa.id == null) return;

    await _tarefasDao.marcarConcluida(tarefa.id!, value);

    // se concluiu agora, gera revisões 7/30/60 a partir de hoje
    if (value) {
      await _revisoesDao.limparPorTarefa(tarefa.id!);

      final hoje = _dateOnly(DateTime.now());
      final revisoes = <Revisao>[
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
      ];
      await _revisoesDao.inserirEmLote(revisoes);
    }

    await carregarTarefas();
    await gerarPlanoDoDia(data: dataSelecionada);
  }

  // usado pela tela de detalhe (questões/acertos/fonte/concluída)
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

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
