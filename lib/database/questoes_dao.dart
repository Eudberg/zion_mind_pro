import '../models/questao.dart';
import 'db_helper.dart';

class QuestoesDao {
  // Correção: Substituído DbHelper.instance por DbHelper()

  Future<int> inserir(Questao questao) async {
    // Acessamos o banco chamando o construtor factory DbHelper()
    final db = await DbHelper().database;
    return db.insert('questoes', questao.toMap());
  }

  Future<List<Questao>> listarTodas() async {
    final db = await DbHelper().database;
    final result = await db.query('questoes', orderBy: 'data DESC');
    return result.map((json) => Questao.fromMap(json)).toList();
  }
}
