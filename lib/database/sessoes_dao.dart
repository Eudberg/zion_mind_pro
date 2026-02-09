import '../models/sessao_estudo.dart';
import 'db_helper.dart';

class SessoesDao {
  Future<int> inserir(SessaoEstudo sessao) async {
    final db = await DbHelper.instance.database;
    return db.insert('sessoes_estudo', sessao.toMap());
  }

  Future<List<SessaoEstudo>> listarPorTarefa(int tarefaId) async {
    final db = await DbHelper.instance.database;
    final result = await db.query(
      'sessoes_estudo',
      where: 'tarefa_id = ?',
      whereArgs: [tarefaId],
      orderBy: 'inicio DESC',
    );
    return result.map((json) => SessaoEstudo.fromMap(json)).toList();
  }

  Future<List<SessaoEstudo>> listarTodas() async {
    final db = await DbHelper.instance.database;
    final result = await db.query(
      'sessoes_estudo',
      orderBy: 'inicio DESC',
    );
    return result.map((json) => SessaoEstudo.fromMap(json)).toList();
  }
}
