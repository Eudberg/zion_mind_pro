import 'package:sqflite/sqflite.dart';
import 'db_helper.dart'; // Certifique-se que este import está correto
import '../models/tarefa_trilha.dart';

class TarefasTrilhaDao {
  // Nome da tabela
  static const String _tableName = 'tarefas_trilha';

  // --- AQUI ESTAVA FALTANDO: O GETTER (O ATALHO) ---
  // Isso permite usar "await database" em qualquer lugar desta classe
  Future<Database> get database async => await DbHelper.instance.database;

  // Insere lista (Batch)
  Future<void> inserirEmLote(List<TarefaTrilha> tarefas) async {
    final db = await database; // Agora funciona!
    final batch = db.batch();

    for (var tarefa in tarefas) {
      batch.insert(
        _tableName,
        tarefa.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Lista todas
  Future<List<TarefaTrilha>> listarTodas() async {
    final db = await database;
    // Ordena por ordem global para manter a sequência da trilha
    final result = await db.query(_tableName, orderBy: 'ordem_global ASC');
    return result.map((map) => TarefaTrilha.fromMap(map)).toList();
  }

  // Marca como concluída (Simples)
  Future<void> marcarConcluida(int id, bool concluida) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'concluida': concluida ? 1 : 0,
        // Se concluiu, salva agora. Se desmarcou, limpa a data.
        'data_conclusao': concluida ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atualiza campos (Complexo - Onde estava o erro)
  Future<void> atualizarCampos({
    required int tarefaId,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    bool? concluida,
    DateTime? dataConclusao, // Parâmetro novo
    int? minutosExecutados, // Parâmetro novo
  }) async {
    final db = await database; // <--- O ERRO SUMIRÁ AQUI

    Map<String, dynamic> campos = {};

    if (questoes != null) campos['questoes'] = questoes;
    if (acertos != null) campos['acertos'] = acertos;
    if (fonteQuestoes != null) campos['fonte_questoes'] = fonteQuestoes;

    if (concluida != null) {
      campos['concluida'] = concluida ? 1 : 0;

      if (concluida) {
        // Se passou data específica (edição manual), usa ela. Se não, usa Agora.
        campos['data_conclusao'] = (dataConclusao ?? DateTime.now())
            .toIso8601String();
      } else {
        campos['data_conclusao'] = null;
      }
    } else if (dataConclusao != null) {
      // Edição apenas da data, mantendo o status atual
      campos['data_conclusao'] = dataConclusao.toIso8601String();
    }

    if (minutosExecutados != null) {
      campos['ch_efetiva_min'] = minutosExecutados;
    }

    if (campos.isNotEmpty) {
      await db.update(
        _tableName,
        campos,
        where: 'id = ?',
        whereArgs: [tarefaId],
      );
    }
  }

  // Limpa tudo
  Future<void> limparTudo() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
