import '../models/revisao.dart';
import 'db_helper.dart';

class RevisoesDao {
  Future<List<int>> inserirEmLote(List<Revisao> revisoes) async {
    final db = await DbHelper.instance.database;
    final batch = db.batch();
    for (final revisao in revisoes) {
      batch.insert('revisoes', revisao.toMap());
    }
    final result = await batch.commit(noResult: false);
    return result.map((e) => e as int).toList();
  }

  Future<List<Revisao>> listarPorData(DateTime data) async {
    final db = await DbHelper.instance.database;
    final key = _dateKey(data);
    final result = await db.query(
      'revisoes',
      where: 'data_prevista LIKE ?',
      whereArgs: ['$key%'],
      orderBy: 'data_prevista ASC',
    );
    return result.map((json) => Revisao.fromMap(json)).toList();
  }

  Future<void> limparTudo() async {
    final db = await DbHelper.instance.database;
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
