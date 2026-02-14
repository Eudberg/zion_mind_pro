import '../models/revisao.dart';
import 'db_helper.dart';

class RevisoesDao {
  // Correção: Substituído DbHelper.instance por DbHelper() para alinhar com o padrão factory

  Future<void> inserirEmLote(List<Revisao> revisoes) async {
    final db = await DbHelper().database;
    final batch = db.batch();
    for (final r in revisoes) {
      batch.insert('revisoes', r.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Revisao>> listarPorData(DateTime data) async {
    final db = await DbHelper().database;
    final key = _dateKey(data);

    final result = await db.query(
      'revisoes',
      where: 'data_prevista LIKE ?',
      whereArgs: ['$key%'],
      orderBy: 'data_prevista ASC',
    );

    return result.map((json) => Revisao.fromMap(json)).toList();
  }

  Future<void> limparPorTarefa(int tarefaId) async {
    final db = await DbHelper().database;
    await db.delete('revisoes', where: 'tarefa_id = ?', whereArgs: [tarefaId]);
  }

  Future<void> limparTudo() async {
    final db = await DbHelper().database;
    await db.delete('revisoes');
  }

  String _dateKey(DateTime data) {
    final d = DateTime(data.year, data.month, data.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
