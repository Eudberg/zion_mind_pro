import '../models/tarefa_trilha.dart';
import 'db_helper.dart';

class TarefasTrilhaDao {
  Future<int> inserir(TarefaTrilha tarefa) async {
    final db = await DbHelper.instance.database;
    return db.insert('tarefas_trilha', tarefa.toMap());
  }

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
      orderBy: 'data_planejada ASC',
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
      orderBy: 'data_planejada ASC',
    );
    return result.map((json) => TarefaTrilha.fromMap(json)).toList();
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
