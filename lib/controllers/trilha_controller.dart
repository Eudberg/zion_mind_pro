import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../data/trilha_importer.dart';
import '../database/tarefas_trilha_dao.dart';
import '../models/tarefa_trilha.dart';

class TrilhaController extends ChangeNotifier {
  final TarefasTrilhaDao _dao = TarefasTrilhaDao();
  final TrilhaImporter _importer = TrilhaImporter();

  List<TarefaTrilha> _tarefas = [];
  List<TarefaTrilha> get tarefas => _tarefas;

  bool _carregando = false;
  bool get carregando => _carregando;

  Future<void> carregarTarefas() async {
    _carregando = true;
    notifyListeners();

    try {
      _tarefas = await _dao.listarTodas();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> importarCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final tarefasImportadas = await _importer.importarBytes(bytes);

    // Se o import falhar (vazio), não apaga o banco
    if (tarefasImportadas.isEmpty) return;

    await _dao.limparTudo();
    await _dao.inserirEmLote(tarefasImportadas);

    await carregarTarefas();
  }

  Future<void> alternarConcluida(TarefaTrilha tarefa, bool concluida) async {
    final id = tarefa.id;
    if (id == null) return;

    await _dao.marcarConcluida(id, concluida);
    await carregarTarefas();
  }

  Future<void> atualizarTarefaCampos({
    required int tarefaId,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    bool? concluida,
  }) async {
    await _dao.atualizarCampos(
      tarefaId: tarefaId,
      questoes: questoes,
      acertos: acertos,
      fonteQuestoes: fonteQuestoes,
      concluida: concluida,
    );

    await carregarTarefas();
  }
    /// Disciplinas vindas do CSV (usadas na Tela Inicial)
  List<String> get disciplinasDoCsv {
    final set = <String>{};

    for (final t in tarefas) {
      // <- já usa seu getter existente
      final d = (t.disciplina ?? '').trim();
      if (d.isEmpty) continue;

      final norm = d.replaceAll(RegExp(r'\s+'), ' ').trim();
      set.add(norm);
    }

    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// alias opcional (caso alguma tela use "disciplinas")
  List<String> get disciplinas => disciplinasDoCsv;

}
