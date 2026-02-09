import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/trilha_importer.dart';
import '../database/plano_diario_dao.dart';
import '../database/revisoes_dao.dart';
import '../database/tarefas_trilha_dao.dart';
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
  })  : _tarefasDao = tarefasDao ?? TarefasTrilhaDao(),
        _planoDao = planoDao ?? PlanoDiarioDao(),
        _revisoesDao = revisoesDao ?? RevisoesDao();

  int get totalMinutosPlanejados {
    return tarefas.fold(0, (acc, t) => acc + (t.chPlanejadaMin ?? 0));
  }

  int get totalMinutosEfetivos {
    return tarefas.fold(0, (acc, t) => acc + (t.chEfetivaMin ?? 0));
  }

  int get diasAtivos {
    final datas = <String>{};
    for (final t in tarefas) {
      if ((t.chEfetivaMin ?? 0) > 0 && t.dataPlanejada != null) {
        datas.add(_dateKey(t.dataPlanejada!));
      }
    }
    return datas.length;
  }

  double get progresso {
    final planejado = totalMinutosPlanejados;
    if (planejado == 0) return 0;
    return (totalMinutosEfetivos / planejado).clamp(0.0, 1.0);
  }

  Map<int, TarefaTrilha> get tarefasPorId {
    final map = <int, TarefaTrilha>{};
    for (final t in tarefas) {
      if (t.id != null) {
        map[t.id!] = t;
      }
    }
    return map;
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

      if (bytes == null) {
        throw Exception('Nao foi possivel ler o arquivo.');
      }

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

  Future<void> carregarTarefas() async {
    tarefas = await _tarefasDao.listarTodas();
    notifyListeners();
  }

  Future<void> gerarPlanoDoDia({DateTime? data}) async {
    final alvo = _dateOnly(data ?? DateTime.now());
    dataSelecionada = alvo;

    if (tarefas.isEmpty) {
      tarefas = await _tarefasDao.listarTodas();
    }

    final tarefasDia = await _tarefasDao.listarPorData(alvo);
    final revisoesDia = await _revisoesDao.listarPorData(alvo);

    await _planoDao.limparPorData(alvo);

    final itens = <PlanoItem>[];
    for (final tarefa in tarefasDia) {
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

  Future<List<Revisao>> listarRevisoesDoDia({DateTime? data}) async {
    final alvo = _dateOnly(data ?? DateTime.now());
    revisoesDoDia = await _revisoesDao.listarPorData(alvo);
    notifyListeners();
    return revisoesDoDia;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime data) {
    final d = _dateOnly(data);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
