import '../models/tarefa_trilha.dart';
import 'db_helper.dart';

class TarefasTrilhaDao {
  Future<List<int>> inserirEmLote(List<TarefaTrilha> tarefas) async {
    final db = await DbHelper.instance.database;
    final batch = db.batch();
    for (final tarefa in tarefas) {
      batch.insert('tarefas_trilha', tarefa.toMap());
    }
    final result = await batch.commit(noResult: false);
    return result.map((e) => e as int).toList();
  }

  Future<List<TarefaTrilha>> listarTodas() async {
    final db = await DbHelper.instance.database;
    final result = await db.query(
      'tarefas_trilha',
      orderBy: 'ordem_global ASC',
    );
    return result.map((json) => TarefaTrilha.fromMap(json)).toList();
  }

  Future<List<TarefaTrilha>> listarPorData(DateTime data) async {
    final db = await DbHelper.instance.database;
    final key = _dateKey(data);
    final result = await db.query(
      'tarefas_trilha',
      where: 'data_planejada LIKE ?',
      whereArgs: ['$key%'],
      orderBy: 'ordem_global ASC',
    );
    return result.map((json) => TarefaTrilha.fromMap(json)).toList();
  }

  // ✅ pendências acumuladas: data_planejada <= hoje AND concluida=0
  Future<List<TarefaTrilha>> listarPendentesAte(DateTime data) async {
    final db = await DbHelper.instance.database;
    final key = _dateKey(data);
    final result = await db.query(
      'tarefas_trilha',
      where:
          "(data_planejada IS NOT NULL AND data_planejada <= ?) AND concluida = 0",
      whereArgs: ['${key}T23:59:59.999'],
      orderBy: 'data_planejada ASC, ordem_global ASC',
    );
    return result.map((json) => TarefaTrilha.fromMap(json)).toList();
  }

  Future<void> marcarConcluida(int tarefaId, bool concluida) async {
    final db = await DbHelper.instance.database;
    await db.update(
      'tarefas_trilha',
      {'concluida': concluida ? 1 : 0},
      where: 'id = ?',
      whereArgs: [tarefaId],
    );
  }

  Future<void> atualizarCampos({
    required int tarefaId,
    int? questoes,
    int? acertos,
    String? fonteQuestoes,
    bool? concluida,
    int? chEfetivaMin,
  }) async {
    final db = await DbHelper.instance.database;
    final values = <String, dynamic>{};

    if (questoes != null) values['questoes'] = questoes;
    if (acertos != null) values['acertos'] = acertos;
    if (fonteQuestoes != null) values['fonte_questoes'] = fonteQuestoes;
    if (concluida != null) values['concluida'] = concluida ? 1 : 0;
    if (chEfetivaMin != null) values['ch_efetiva_min'] = chEfetivaMin;

    if (values.isEmpty) return;

    await db.update(
      'tarefas_trilha',
      values,
      where: 'id = ?',
      whereArgs: [tarefaId],
    );
  }

  Future<void> limparTudo() async {
    final db = await DbHelper.instance.database;
    await db.delete('tarefas_trilha');
  }

  String _dateKey(DateTime data) {
    final d = DateTime(data.year, data.month, data.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
