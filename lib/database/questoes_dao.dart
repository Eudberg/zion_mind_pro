import '../models/questao.dart';
import 'db_helper.dart';

class QuestoesDao {
  Future<int> inserir(Questao questao) async {
    final db = await DbHelper.instance.database;
    return db.insert('questoes', questao.toMap());
  }

  Future<List<Questao>> listarTodas() async {
    final db = await DbHelper.instance.database;
    final result = await db.query(
      'questoes',
      orderBy: 'data DESC',
    );
    return result.map((json) => Questao.fromMap(json)).toList();
  }
}
