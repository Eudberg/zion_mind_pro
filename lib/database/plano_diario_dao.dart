import '../models/plano_item.dart';
import 'db_helper.dart';

class PlanoDiarioDao {
  // Correção: Alterado de DbHelper.instance para DbHelper()

  Future<List<int>> inserirEmLote(List<PlanoItem> itens) async {
    // Chamamos o singleton através do construtor factory DbHelper()
    final db = await DbHelper().database;
    final batch = db.batch();
    for (final item in itens) {
      batch.insert('plano_diario', item.toMap());
    }
    final result = await batch.commit(noResult: false);
    return result.map((e) => e as int).toList();
  }

  Future<List<PlanoItem>> listarPorData(DateTime data) async {
    final db = await DbHelper().database;
    final key = _dateKey(data);
    final result = await db.query(
      'plano_diario',
      where: 'data LIKE ?',
      whereArgs: ['$key%'],
      orderBy: 'id ASC',
    );
    return result.map((json) => PlanoItem.fromMap(json)).toList();
  }

  Future<void> limparPorData(DateTime data) async {
    final db = await DbHelper().database;
    final key = _dateKey(data);
    await db.delete('plano_diario', where: 'data LIKE ?', whereArgs: ['$key%']);
  }

  Future<void> limparTudo() async {
    final db = await DbHelper().database;
    await db.delete('plano_diario');
  }

  String _dateKey(DateTime data) {
    final d = DateTime(data.year, data.month, data.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
