import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/tarefas_trilha_dao.dart';
import '../database/sessoes_dao.dart';

class BackupService {
  final TarefasTrilhaDAO _tarefasDAO = TarefasTrilhaDAO();
  final SessoesDao _sessoesDAO = SessoesDao();

  Future<String> exportarBackup() async {
    final tarefas = await _tarefasDAO.listarTodas();
    final sessoes = await _sessoesDAO.listarTodas();

    final mapa = {
      "tarefas": tarefas.map((t) => t.toMap()).toList(),
      "sessoes": sessoes.map((s) => s.toMap()).toList(),
      "dataExportacao": DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent("  ").convert(mapa);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/backup_zion_mind.json");

    await file.writeAsString(jsonString);

    return file.path;
  }
}
